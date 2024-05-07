# frozen_string_literal: true

require 'hackle/event'
require 'hackle/decision'
require 'hackle/config'
require 'hackle/remote_config'
require 'hackle/version'
require 'hackle/internal/concurrent/executors'
require 'hackle/internal/logger/logger'
require 'hackle/internal/model/sdk'
require 'hackle/internal/model/decision_reason'
require 'hackle/internal/config/parameter_config'
require 'hackle/internal/workspace/http_workspace_fetcher'
require 'hackle/internal/workspace/polling_workspace_fetcher'
require 'hackle/internal/event/user_event_dispatcher'
require 'hackle/internal/event/user_event_processor'
require 'hackle/internal/http/http_client'
require 'hackle/internal/core/hackle_core'
require 'hackle/internal/user/hackle_user_resolver'

module Hackle
  #
  # The entry point of Hackle SDKs.
  #
  class Client
    # @param core [Hackle::Core]
    # @param user_resolver [Hackle::HackleUserResolver]
    def initialize(core:, user_resolver:)
      # @type [Hackle::Core]
      @core = core

      # @type [Hackle::HackleUserResolver]
      @user_resolver = user_resolver
    end

    #
    # Instantiates a Hackle client.
    #
    # @param sdk_key [String]
    # @param config [Hackle::Config]
    # @return [Hackle::Client]
    #
    def self.create(sdk_key:, config: Config.builder.build)
      Log.init(config.logger)

      sdk = Sdk.new(name: 'ruby-sdk', version: Hackle::VERSION, key: sdk_key)

      http_workspace_fetcher = HttpWorkspaceFetcher.new(
        http_client: HttpClient.create(base_url: config.sdk_url, sdk: sdk),
        sdk: sdk
      )
      workspace_fetcher = PollingWorkspaceFetcher.new(
        http_workspace_fetcher: http_workspace_fetcher,
        scheduler: Executors.scheduler,
        polling_interval_seconds: 10.0
      )

      event_dispatcher = UserEventDispatcher.create(
        http_client: HttpClient.create(base_url: config.event_url, sdk: sdk),
        executor: Executors.thread_pool(pool_size: 2, queue_capacity: 64)
      )

      event_processor = DefaultUserEventProcessor.new(
        queue: SizedQueue.new(10_000),
        event_dispatcher: event_dispatcher,
        event_dispatch_size: 100,
        flush_scheduler: Executors.scheduler,
        flush_interval_seconds: 10.0,
        shutdown_timeout_seconds: 10.0
      )

      workspace_fetcher.start
      event_processor.start

      core = Core.create(
        workspace_fetcher: workspace_fetcher,
        event_processor: event_processor
      )

      Client.new(
        core: core,
        user_resolver: HackleUserResolver.new
      )
    end

    #
    # Decide the variation to expose to the user for experiment.
    #
    # @param experiment_key [Integer]
    # @param user [Hackle::User]
    #
    # @return [String] the decided variation for the user
    #
    def variation(experiment_key, user)
      variation_detail(experiment_key, user).variation
    end

    #
    # Decide the variation to expose to the user for experiment, and returns an object that
    # describes the way the variation was decided.
    #
    # @param experiment_key [Integer] the unique key of the experiment. MUST NOT be nil.
    # @param user [Hackle::User] the user to participate in the experiment. MUST NOT be nil.
    #
    # @return [Hackle::ExperimentDecision] an object describing the result
    #
    def variation_detail(experiment_key, user)
      unless experiment_key.is_a?(Integer)
        Log.get.warn { "Invalid experiment key: #{experiment_key} (expected: integer)" }
        return ExperimentDecision.new('A', DecisionReason::INVALID_INPUT, ParameterConfig.empty)
      end

      hackle_user = @user_resolver.resolve_or_nil(user)
      if hackle_user.nil?
        Log.get.warn { "Invalid hackle user: #{user}" }
        return ExperimentDecision.new('A', DecisionReason::INVALID_INPUT, ParameterConfig.empty)
      end

      @core.experiment(experiment_key, hackle_user, 'A')
    rescue => e
      Log.get.error { "Unexpected error while deciding variation of experiment[#{experiment_key}]: #{e.inspect}]" }
      ExperimentDecision.new('A', DecisionReason::EXCEPTION, ParameterConfig.empty)
    end

    #
    # Decide whether the feature is turned on to the user.
    #
    # @param feature_key [Integer] the unique key of the feature.
    # @param user [Hackle::User] the user requesting the feature.
    #
    # @return [TrueClass] of the feature is on
    # @return [FalseClass] of the feature is off
    #
    def is_feature_on(feature_key, user)
      feature_flag_detail(feature_key, user).is_on
    end

    #
    # Decide whether the feature is turned on to the user, and returns an object that
    # describes the way the value was decided.
    #
    # @param feature_key [Integer] the unique key of the feature.
    # @param user [Hackle::User] the user requesting the feature.
    #
    # @return [Hackle::FeatureFlagDecision] an object describing the result
    #
    def feature_flag_detail(feature_key, user)
      unless feature_key.is_a?(Integer)
        Log.get.warn { "Invalid feature key: #{feature_key} (expected: integer)" }
        return FeatureFlagDecision.new(false, DecisionReason::INVALID_INPUT, ParameterConfig.empty)
      end

      hackle_user = @user_resolver.resolve_or_nil(user)
      if hackle_user.nil?
        Log.get.warn { "Invalid hackle user: #{user}" }
        return FeatureFlagDecision.new(false, DecisionReason::INVALID_INPUT, ParameterConfig.empty)
      end

      @core.feature_flag(feature_key, hackle_user)
    rescue => e
      Log.get.error { "Unexpected error while deciding feature flag[#{feature_key}]: #{e.inspect}]" }
      FeatureFlagDecision.new(false, DecisionReason::EXCEPTION, ParameterConfig.empty)
    end

    #
    # Returns a instance of Hackle::RemoteConfig.
    #
    # @param user [Hackle::User] the user requesting the remote config.
    #
    # @return [Hackle::RemoteConfig]
    #
    def remote_config(user)
      RemoteConfig.new(user: user, user_resolver: @user_resolver, core: @core)
    end

    #
    # Records the event that occurred by the user.
    #
    # @param event [Hackle::Event] the event that occurred.
    # @param user [Hackle::User] the user that occurred the event.
    #
    def track(event, user)
      unless event.is_a?(Event)
        Log.get.warn { "Invalid event: #{event} (expected: Hackle::Event)" }
        return
      end

      unless event.valid?
        Log.get.error { "Invalid event: #{event.error_or_nil}" }
        return
      end

      hackle_user = @user_resolver.resolve_or_nil(user)
      if hackle_user.nil?
        Log.get.warn { "Invalid hackle user: #{user}" }
        return FeatureFlagDecision.new(false, DecisionReason::INVALID_INPUT, ParameterConfig.empty)
      end

      @core.track(event, hackle_user)
    rescue => e
      Log.get.error { "Unexpected error while tracking event: #{e.inspect}]" }
    end

    #
    # Shutdown the background task and release the resources used for the background task.
    # This should only be called when the application shutdown.
    #
    def close
      @core.close
    end
  end
end

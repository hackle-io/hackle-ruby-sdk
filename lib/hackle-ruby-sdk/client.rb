# frozen_string_literal: true

module Hackle

  #
  # A client for Hackle API.
  #
  class Client
    def initialize(config, workspace_fetcher, event_processor, decider)
      @logger = config.logger
      @workspace_fetcher = workspace_fetcher
      @event_processor = event_processor
      @decider = decider
    end

    #
    # Decide the variation to expose to the user for experiment.
    #
    # This method return the control variation 'A' if:
    # - The experiment key is invalid
    # - The experiment has not started yet
    # - The user is not allocated to the experiment
    # - The decided variation has been dropped
    #
    # @param experiment_key [Integer] The unique key of the experiment.
    # @param user_id [String] The identifier of your customer. (e.g. user_email, account_id, decide_id, etc.)
    # @param default_variation [String] The default variation of the experiment.
    #
    # @return [String] The decided variation for the user, or default variation
    #
    def variation(experiment_key, user_id, default_variation = 'A')

      return default_variation if experiment_key.nil?
      return default_variation if user_id.nil?

      workspace = @workspace_fetcher.fetch
      return default_variation if workspace.nil?

      experiment = workspace.get_experiment(experiment_key)
      return default_variation if experiment.nil?

      decision = @decider.decide(experiment, user_id)
      case decision
      when Decision::NotAllocated
        default_variation
      when Decision::ForcedAllocated
        decision.variation_key
      when Decision::NaturalAllocated
        @event_processor.process(Event::Exposure.new(user_id, experiment, decision.variation))
        decision.variation.key
      else
        default_variation
      end
    end

    #
    # Records the events performed by the user.
    #
    # @param event_key [String]  The unique key of the events.
    # @param user_id [String] The identifier of user that performed the vent.
    # @param value [Float] Additional numeric value of the events (e.g. purchase_amount, api_latency, etc.)
    #
    def track(event_key, user_id, value = nil)

      return if event_key.nil?
      return if user_id.nil?

      workspace = @workspace_fetcher.fetch
      return if workspace.nil?

      event_type = workspace.get_event_type(event_key)
      return if event_type.nil?

      @event_processor.process(Event::Track.new(user_id, event_type, value))
    end

    #
    # Shutdown the background task and release the resources used for the background task.
    #
    def close
      @workspace_fetcher.stop!
      @event_processor.stop!
    end

    #
    # Instantiates a Hackle client.
    #
    # @param sdk_key [String] The SDK key of your Hackle environment
    # @param config [Config] An optional client configuration
    #
    # @return [Client] The Hackle client instance.
    #
    def self.create(sdk_key, config = Config.new)
      sdk_info = SdkInfo.new(sdk_key)

      http_workspace_fetcher = HttpWorkspaceFetcher.new(config, sdk_info)
      polling_workspace_fetcher = PollingWorkspaceFetcher.new(config, http_workspace_fetcher)

      event_dispatcher = EventDispatcher.new(config, sdk_info)
      event_processor = EventProcessor.new(config, event_dispatcher)

      polling_workspace_fetcher.start!
      event_processor.start!

      Client.new(config, polling_workspace_fetcher, event_processor, Decider.new)
    end
  end
end

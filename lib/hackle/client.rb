# frozen_string_literal: true

require 'hackle/decision/bucketer'
require 'hackle/decision/decider'

require 'hackle/events/user_event'
require 'hackle/events/event_dispatcher'
require 'hackle/events/event_processor'

require 'hackle/http/http'

require 'hackle/models/bucket'
require 'hackle/models/event'
require 'hackle/models/event_type'
require 'hackle/models/experiment'
require 'hackle/models/slot'
require 'hackle/models/user'
require 'hackle/models/variation'

require 'hackle/workspaces/http_workspace_fetcher'
require 'hackle/workspaces/polling_workspace_fetcher'
require 'hackle/workspaces/workspace'

module Hackle

  #
  # A client for Hackle API.
  #
  class Client

    #
    # Initializes a Hackle client.
    #
    # @param config [Config]
    # @param workspace_fetcher [PollingWorkspaceFetcher]
    # @param event_processor [EventProcessor]
    # @param decider [Decider]
    #
    def initialize(config:, workspace_fetcher:, event_processor:, decider:)
      @logger = config.logger

      # @type [PollingWorkspaceFetcher]
      @workspace_fetcher = workspace_fetcher

      # @type [EventProcessor]
      @event_processor = event_processor

      # @type [Decider]
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
    # @param experiment_key [Integer] The unique key of the experiment. MUST NOT be nil.
    # @param user [User] the user to participate in the experiment. MUST NOT be nil.
    # @param default_variation [String] The default variation of the experiment.
    #
    # @return [String] The decided variation for the user, or default variation
    #
    def variation(experiment_key:, user:, default_variation: 'A')

      return default_variation if experiment_key.nil? || !experiment_key.is_a?(Integer)
      return default_variation if user.nil? || !user.is_a?(User) || !user.valid?

      workspace = @workspace_fetcher.fetch
      return default_variation if workspace.nil?

      experiment = workspace.get_experiment(experiment_key: experiment_key)
      return default_variation if experiment.nil?

      decision = @decider.decide(experiment: experiment, user: user)
      case decision
      when Decision::NotAllocated
        default_variation
      when Decision::ForcedAllocated
        decision.variation_key
      when Decision::NaturalAllocated
        exposure_event = UserEvent::Exposure.new(user: user, experiment: experiment, variation: decision.variation)
        @event_processor.process(event: exposure_event)
        decision.variation.key
      else
        default_variation
      end

    rescue => e
      @logger.error { "Unexpected error while deciding variation for experiment[#{experiment_key}]. Returning default variation[#{default_variation}]: #{e.inspect}" }
      default_variation
    end

    #
    # Records the event that occurred by the user.
    #
    # @param event [Event] the event that occurred.
    # @param user [User] the user that occurred the event.
    #
    def track(event:, user:)

      return if event.nil? || !event.is_a?(Event) || !event.valid?
      return if user.nil? || !user.is_a?(User) || !user.valid?

      workspace = @workspace_fetcher.fetch
      return if workspace.nil?

      event_type = workspace.get_event_type(event_type_key: event.key)
      track_event = UserEvent::Track.new(user: user, event_type: event_type, event: event)
      @event_processor.process(event: track_event)

    rescue => e
      @logger.error { "Unexpected error while tracking event: #{e.inspect}" }
    end

    #
    # Shutdown the background task and release the resources used for the background task.
    #
    def close
      @workspace_fetcher.stop!
      @event_processor.stop!
    end
  end
end

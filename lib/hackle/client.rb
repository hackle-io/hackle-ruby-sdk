# frozen_string_literal: true

require 'hackle/decision/bucketer'
require 'hackle/decision/decider'

require 'hackle/events/event'
require 'hackle/events/event_dispatcher'
require 'hackle/events/event_processor'

require 'hackle/http/http'

require 'hackle/models/bucket'
require 'hackle/models/event_type'
require 'hackle/models/experiment'
require 'hackle/models/slot'
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
    def variation(experiment_key:, user_id:, default_variation: 'A')

      return default_variation if experiment_key.nil?
      return default_variation if user_id.nil?

      workspace = @workspace_fetcher.fetch
      return default_variation if workspace.nil?

      experiment = workspace.get_experiment(experiment_key: experiment_key)
      return default_variation if experiment.nil?

      decision = @decider.decide(experiment: experiment, user_id: user_id)
      case decision
      when Decision::NotAllocated
        default_variation
      when Decision::ForcedAllocated
        decision.variation_key
      when Decision::NaturalAllocated
        exposure_event = Event::Exposure.new(user_id: user_id, experiment: experiment, variation: decision.variation)
        @event_processor.process(event: exposure_event)
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
    def track(event_key:, user_id:, value: nil)

      return if event_key.nil?
      return if user_id.nil?

      workspace = @workspace_fetcher.fetch
      return if workspace.nil?

      event_type = workspace.get_event_type(event_type_key: event_key)
      return if event_type.nil?

      track_event = Event::Track.new(user_id: user_id, event_type: event_type, value: value)
      @event_processor.process(event: track_event)
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
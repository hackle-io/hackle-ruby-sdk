# frozen_string_literal: true

require "securerandom"

module Hackle
  class UserEvent

    # @return [String]
    attr_reader :insert_id

    # @return [Integer]
    attr_reader :timestamp

    # @return [HackleUser]
    attr_reader :user

    # @param insert_id [String]
    # @param timestamp [Integer]
    # @param user [HackleUser]
    def initialize(insert_id:, timestamp:, user:)
      @insert_id = insert_id
      @timestamp = timestamp
      @user = user
    end

    class << self

      # @param evaluation [ExperimentEvaluation]
      # @param properties [Hash{String => Object}]
      # @param user [HackleUser]
      # @param timestamp [Integer]
      # @return [Hackle::ExposureEvent]
      def exposure(evaluation, properties, user, timestamp)
        ExposureEvent.new(
          insert_id: SecureRandom.uuid,
          timestamp: timestamp,
          user: user,
          experiment: evaluation.experiment,
          variation_id: evaluation.variation_id,
          variation_key: evaluation.variation_key,
          decision_reason: evaluation.reason,
          properties: properties
        )
      end

      # @param event_type [EventType]
      # @param event [Event]
      # @param user [HackleUser]
      # @param timestamp [Integer]
      # @return [Hackle::TrackEvent]
      def track(event_type, event, user, timestamp)
        TrackEvent.new(
          insert_id: SecureRandom.uuid,
          timestamp: timestamp,
          user: user,
          event_type: event_type,
          event: event
        )
      end

      # @param evaluation [RemoteConfigEvaluation]
      # @param properties [Hash{String => Object}]
      # @param user [HackleUser]
      # @param timestamp [Integer]
      # @return [Hackle::RemoteConfigEvent]
      def remote_config(evaluation, properties, user, timestamp)
        RemoteConfigEvent.new(
          insert_id: SecureRandom.uuid,
          timestamp: timestamp,
          user: user,
          parameter: evaluation.parameter,
          value_id: evaluation.value_id,
          decision_reason: evaluation.reason,
          properties: properties
        )
      end
    end
  end

  class ExposureEvent < UserEvent

    # @return [Experiment]
    attr_reader :experiment

    # @return [Integer, nil]
    attr_reader :variation_id

    # @return [String]
    attr_reader :variation_key

    # @return [String]
    attr_reader :decision_reason

    # @return [Hash{String => Object}]
    attr_reader :properties

    # @param insert_id [String]
    # @param timestamp [Integer]
    # @param user [HackleUser]
    # @param experiment [Experiment]
    # @param variation_id [Integer, nil]
    # @param variation_key [String]
    # @param decision_reason [String]
    # @param properties [Hash{String => Object}]
    def initialize(
      insert_id:,
      timestamp:,
      user:,
      experiment:,
      variation_id:,
      variation_key:,
      decision_reason:,
      properties:
    )
      super(insert_id: insert_id, timestamp: timestamp, user: user)
      @experiment = experiment
      @variation_id = variation_id
      @variation_key = variation_key
      @decision_reason = decision_reason
      @properties = properties
    end
  end

  class TrackEvent < UserEvent

    # @return [EventType]
    attr_reader :event_type

    # @return [Event]
    attr_reader :event

    # @param insert_id [String]
    # @param timestamp [Integer]
    # @param user [HackleUser]
    # @param event_type [EventType]
    # @param event [Event]
    def initialize(
      insert_id:,
      timestamp:,
      user:,
      event_type:,
      event:
    )
      super(insert_id: insert_id, timestamp: timestamp, user: user)
      @event_type = event_type
      @event = event
    end
  end

  class RemoteConfigEvent < UserEvent

    # @return [RemoteConfigParameter]
    attr_reader :parameter

    # @return [Integer, nil]
    attr_reader :value_id

    # @return [String]
    attr_reader :decision_reason

    # @return [Hash{String => Object}]
    attr_reader :properties

    # @param insert_id [String]
    # @param timestamp [Integer]
    # @param user [HackleUser]
    # @param parameter [RemoteConfigParameter]
    # @param value_id [Integer, nil]
    # @param decision_reason [String]
    # @param properties [Hash{String => Object}]
    def initialize(
      insert_id:,
      timestamp:,
      user:,
      parameter:,
      value_id:,
      decision_reason:,
      properties:
    )
      super(insert_id: insert_id, timestamp: timestamp, user: user)
      @parameter = parameter
      @value_id = value_id
      @decision_reason = decision_reason
      @properties = properties
    end
  end
end

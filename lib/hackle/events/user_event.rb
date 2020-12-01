# frozen_string_literal: true

module Hackle

  class UserEvent

    # @!attribute [r] timestamp
    #  @return [Integer]
    # @!attribute [r] user
    #  @return [User]
    attr_reader :timestamp, :user

    # @param user [User]
    def initialize(user:)
      @timestamp = UserEvent.generate_timestamp
      @user = user
    end

    class Exposure < UserEvent

      # @!attribute [r] experiment
      #  @return [Experiment]
      # @!attribute [r] variation
      #  @return [Variation]
      attr_reader :experiment, :variation

      # @param user [User]
      # @param experiment [Experiment]
      # @param variation [Variation]
      def initialize(user:, experiment:, variation:)
        super(user: user)
        @experiment = experiment
        @variation = variation
      end
    end


    class Track < UserEvent

      # @!attribute [r] event_type
      #  @return [EventType]
      # @!attribute [r] event
      #  @return [Event]
      attr_reader :event_type, :event

      # @param user [User]
      # @param event_type [EventType]
      # @param event [Event]
      def initialize(user:, event_type:, event:)
        super(user: user)
        @event_type = event_type
        @event = event
      end
    end

    # @return [Integer]
    def self.generate_timestamp
      (Time.now.to_f * 1000).to_i
    end
  end
end

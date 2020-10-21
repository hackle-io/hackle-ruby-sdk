# frozen_string_literal: true

module Hackle
  class Event
    attr_reader :timestamp, :user_id

    class Exposure < Event
      attr_reader :experiment, :variation

      def initialize(user_id, experiment, variation)
        @timestamp = Event.generate_timestamp
        @user_id = user_id
        @experiment = experiment
        @variation = variation
      end
    end

    class Track < Event
      attr_reader :event_type, :value

      def initialize(user_id, event_type, value = nil)
        @timestamp = Event.generate_timestamp
        @user_id = user_id
        @event_type = event_type
        @value = value
      end
    end

    def self.generate_timestamp
      (Time.now.to_f * 1000).to_i
    end
  end
end

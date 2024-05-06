# frozen_string_literal: true

require 'hackle/internal/logger/logger'

module Hackle

  module UserEventProcessor
    # @param event [UserEvent]
    def process(event) end

    def start
    end

    def stop
    end
  end

  # noinspection RubyTooManyInstanceVariablesInspection
  class DefaultUserEventProcessor
    include UserEventProcessor
    # @param queue [SizedQueue]
    # @param event_dispatcher [UserEventDispatcher]
    # @param event_dispatch_size [Integer]
    # @param flush_scheduler [Scheduler]
    # @param flush_interval_seconds [Float]
    # @param shutdown_timeout_seconds [Float]
    def initialize(
      queue:,
      event_dispatcher:,
      event_dispatch_size:,
      flush_scheduler:,
      flush_interval_seconds:,
      shutdown_timeout_seconds:
    )
      # @type [SizedQueue]
      @queue = queue

      # @type [UserEventDispatcher]
      @event_dispatcher = event_dispatcher

      # @type [Integer]
      @event_dispatch_size = event_dispatch_size

      # @type [Scheduler]
      @flush_scheduler = flush_scheduler

      # @type [Float]
      @flush_interval_seconds = flush_interval_seconds

      # @type [Float]
      @shutdown_timeout_seconds = shutdown_timeout_seconds

      # @type [ScheduledJob, nil]
      @flushing_job = nil

      # @type [Thread, nil]
      @consuming_task = nil

      # @type [boolean]
      @is_started = false

      # @type [Array<UserEvent>]
      @current_batch = []
    end

    # @param event [UserEvent]
    def process(event)
      produce(message: Message::Event.new(event))
    end

    def start
      if @is_started
        Log.get.info { "#{UserEventProcessor} is already started." }
        return
      end

      @consuming_task = Thread.new { consuming }
      @flushing_job = @flush_scheduler.schedule_periodically(@flush_interval_seconds, -> { flush })
      @is_started = true
      Log.get.info { "#{UserEventProcessor} started. Flush event every #{@flush_interval_seconds} seconds." }
    end

    def stop
      return unless @is_started

      Log.get.info { "Shutting down #{UserEventProcessor}" }

      @flushing_job&.cancel

      produce(message: Message::Shutdown.new, non_block: false)
      @consuming_task&.join(@shutdown_timeout_seconds)

      @event_dispatcher.shutdown

      @is_started = false
    end

    private

    # @param message [Message]
    # @param non_block [boolean]
    def produce(message:, non_block: true)
      @queue.push(message, non_block)
    rescue ThreadError
      Log.get.warn { 'Events are produced faster than can be consumed. Some events will be dropped.' }
    end

    def flush
      produce(message: Message::Flush.new)
    end

    def consuming
      loop do
        message = @queue.pop
        case message
        when Message::Event
          consume_event(message.event)
        when Message::Flush
          dispatch_events
        when Message::Shutdown
          break
        else
          Log.get.error { "Unsupported message type: #{message.class}" }
        end
      rescue => e
        Log.get.error { "Unexpected error in event processor: #{e.inspect}" }
      end
    rescue => e
      Log.get.error { "Unexpected error in event processor: #{e.inspect}" }
    ensure
      dispatch_events
    end

    # @param event [UserEvent]
    def consume_event(event)
      @current_batch << event
      dispatch_events if @current_batch.size >= @event_dispatch_size
    end

    def dispatch_events
      return if @current_batch.empty?

      @event_dispatcher.dispatch(@current_batch)
      @current_batch = []
    end

    class Message
      class Event < Message
        # @return [UserEvent]
        attr_reader :event

        # @param event [UserEvent]
        def initialize(event)
          super()
          @event = event
        end
      end

      class Flush < Message
      end

      class Shutdown < Message
      end
    end
  end
end

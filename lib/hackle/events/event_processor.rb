# frozen_string_literal: true

module Hackle

  class EventProcessor

    DEFAULT_FLUSH_INTERVAL = 10

    def initialize(config:, event_dispatcher:)
      @logger = config.logger
      @event_dispatcher = event_dispatcher
      @message_processor = MessageProcessor.new(config: config, event_dispatcher: event_dispatcher)
      @flush_task = Concurrent::TimerTask.new(execution_interval: DEFAULT_FLUSH_INTERVAL) { flush }
      @consume_task = nil
      @running = false
    end

    def start!
      return if @running

      @consume_task = Thread.new { @message_processor.consuming_loop }
      @flush_task.execute
      @running = true
    end

    def stop!
      return unless @running

      @message_processor.produce(message: Message::Shutdown.new, non_block: false)
      @consume_task.join(10)
      @flush_task.shutdown
      @event_dispatcher.shutdown

      @running = false
    end

    def process(event:)
      @message_processor.produce(message: Message::Event.new(event))
    end

    def flush
      @message_processor.produce(message: Message::Flush.new)
    end

    class Message
      class Event < Message
        attr_reader :event

        def initialize(event)
          @event = event
        end
      end

      class Flush < Message
      end

      class Shutdown < Message
      end
    end

    class MessageProcessor

      DEFAULT_MESSAGE_QUEUE_CAPACITY = 1000
      DEFAULT_MAX_EVENT_DISPATCH_SIZE = 500

      def initialize(config:, event_dispatcher:)
        @logger = config.logger
        @event_dispatcher = event_dispatcher
        @message_queue = SizedQueue.new(DEFAULT_MESSAGE_QUEUE_CAPACITY)
        @random = Random.new
        @consumed_events = []
      end

      def produce(message:, non_block: true)
        @message_queue.push(message, non_block)
      rescue ThreadError
        if @random.rand(1..100) == 1 # log only 1% of the time
          @logger.warn { 'Events are produced faster than can be consumed. Some events will be dropped.' }
        end
      end

      def consuming_loop
        loop do
          message = @message_queue.pop
          case message
          when Message::Event
            consume_event(event: message.event)
          when Message::Flush
            dispatch_events
          when Message::Shutdown
            break
          end
        end
      rescue => e
        @logger.warn { "Uncaught exception in events message processor: #{e.inspect}" }
      ensure
        dispatch_events
      end

      private

      def consume_event(event:)
        @consumed_events << event
        dispatch_events if @consumed_events.length >= DEFAULT_MAX_EVENT_DISPATCH_SIZE
      end

      def dispatch_events
        return if @consumed_events.empty?

        @event_dispatcher.dispatch(events: @consumed_events)
        @consumed_events = []
      end
    end
  end
end

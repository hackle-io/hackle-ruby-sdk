# frozen_string_literal: true

module Hackle
  class EventDispatcher

    DEFAULT_DISPATCH_WORKER_SIZE = 2
    DEFAULT_DISPATCH_QUEUE_CAPACITY = 50

    def initialize(config:, sdk_info:)
      @logger = config.logger
      @client = HTTP.client(base_uri: config.event_uri)
      @headers = HTTP.sdk_headers(sdk_info: sdk_info)
      @dispatcher_executor = Concurrent::ThreadPoolExecutor.new(
        min_threads: DEFAULT_DISPATCH_WORKER_SIZE,
        max_threads: DEFAULT_DISPATCH_WORKER_SIZE,
        max_queue: DEFAULT_DISPATCH_QUEUE_CAPACITY
      )
    end

    def dispatch(events:)
      payload = create_payload(events: events)
      begin
        @dispatcher_executor.post { dispatch_payload(payload: payload) }
      rescue Concurrent::RejectedExecutionError
        @logger.warn { 'Dispatcher executor queue is full. Event dispatch rejected' }
      end
    end

    def shutdown
      @dispatcher_executor.shutdown
      unless @dispatcher_executor.wait_for_termination(10)
        @logger.warn { 'Failed to dispatch previously submitted events' }
      end
    end

    private

    def dispatch_payload(payload:)
      request = Net::HTTP::Post.new('/api/v1/events', @headers)
      request.content_type = 'application/json'
      request.body = payload.to_json

      response = @client.request(request)

      status_code = response.code.to_i
      HTTP.check_successful(status_code: status_code)
    rescue => e
      @logger.error { "Failed to dispatch events: #{e.inspect}" }
    end

    def create_payload(events:)
      exposure_events = []
      track_events = []
      events.each do |event|
        case event
        when Event::Exposure
          exposure_events << create_exposure_event(event)
        when Event::Track
          track_events << create_track_event(event)
        end
      end
      {
        exposureEvents: exposure_events,
        trackEvents: track_events
      }
    end

    def create_exposure_event(event)
      {
        timestamp: event.timestamp,
        userId: event.user_id,
        experimentId: event.experiment.id,
        experimentKey: event.experiment.key,
        variationId: event.variation.id,
        variationKey: event.variation.key
      }
    end

    def create_track_event(event)
      {
        timestamp: event.timestamp,
        userId: event.user_id,
        eventTypeId: event.event_type.id,
        eventTypeKey: event.event_type.key,
        value: event.value
      }
    end
  end
end
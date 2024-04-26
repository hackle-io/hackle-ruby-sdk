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
        when UserEvent::Exposure
          exposure_events << create_exposure_event(event)
        when UserEvent::Track
          track_events << create_track_event(event)
        end
      end
      {
        exposureEvents: exposure_events,
        trackEvents: track_events
      }
    end

    #
    # @param exposure [UserEvent::Exposure]
    #
    def create_exposure_event(exposure)
      {
        timestamp: exposure.timestamp,
        userId: exposure.user.id,
        experimentId: exposure.experiment.id,
        experimentKey: exposure.experiment.key,
        variationId: exposure.variation.id,
        variationKey: exposure.variation.key
      }
    end

    #
    # @param track [UserEvent::Track]
    #
    def create_track_event(track)
      {
        timestamp: track.timestamp,
        userId: track.user.id,
        eventTypeId: track.event_type.id,
        eventTypeKey: track.event_type.key,
        value: track.event.value,
        properties: track.event.properties
      }
    end
  end
end

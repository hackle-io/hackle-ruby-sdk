# frozen_string_literal: true

require 'json'
require 'hackle/internal/http/http'

module Hackle
  class UserEventDispatcher
    # @param http_client [HttpClient]
    # @param executor [ThreadPoolExecutor]
    # @param serializer [UserEventSerializer]
    def initialize(http_client:, executor:, serializer:)
      # @type [HttpClient]
      @http_client = http_client
      # @type [ThreadPoolExecutor]
      @executor = executor
      @serializer = serializer
      @url = '/api/v2/events'
    end

    # @param http_client [HttpClient]
    # @param executor [ThreadPoolExecutor]
    def self.create(http_client:, executor:)
      UserEventDispatcher.new(
        http_client: http_client,
        executor: executor,
        serializer: UserEventSerializer.new
      )
    end

    # @param events [Array<UserEvent>]
    def dispatch(events)
      payload = @serializer.serialize(events)
      begin
        @executor.post { dispatch_internal(payload) }
      rescue => e
        Log.get.error { "Unexpected error while posting events: #{e.inspect}" }
      end
    end

    def shutdown
      @executor.shutdown
      return if @executor.wait_for_termination(10)

      Log.get.warn { 'Failed to dispatch previously submitted events' }
    end

    private

    # @param payload [Hash]
    def dispatch_internal(payload)
      request = create_request(payload)
      response = @http_client.execute(request)
      handle_response(response)
    rescue => e
      Log.get.error { "Failed to dispatch events: #{e.inspect}" }
    end

    # @param payload [Hash]
    # @return [Net::HTTPRequest]
    def create_request(payload)
      request = Net::HTTP::Post.new(@url)
      request.content_type = 'application/json'
      request.body = payload.to_json
      request
    end

    # @param response [Net::HTTPResponse]
    def handle_response(response)
      raise "http status code: #{response.code}" unless HTTP.successful? response
    end
  end

  class UserEventSerializer
    # @param events [Array<UserEvent>]
    # @return [Hash]
    def serialize(events)
      exposure_events = []
      track_events = []
      remote_config_events = []

      events.each do |event|
        exposure_events << exposure_event(event) if event.is_a? ExposureEvent
        track_events << track_event(event) if event.is_a? TrackEvent
        remote_config_events << remote_config_event(event) if event.is_a? RemoteConfigEvent
      end
      {
        exposureEvents: exposure_events,
        trackEvents: track_events,
        remoteConfigEvents: remote_config_events
      }
    end

    # @param event [ExposureEvent]
    # @return [Hash]
    def exposure_event(event)
      {
        insertId: event.insert_id,
        timestamp: event.timestamp,

        userId: event.user.identifiers['$id'],
        identifiers: event.user.identifiers,
        userProperties: event.user.properties,
        hackleProperties: {},

        experimentId: event.experiment.id,
        experimentKey: event.experiment.key,
        experimentType: event.experiment.type.name,
        experimentVersion: event.experiment.version,
        variationId: event.variation_id,
        variationKey: event.variation_key,
        decisionReason: event.decision_reason,
        properties: event.properties
      }
    end

    # @param event [TrackEvent]
    # @return [Hash]
    def track_event(event)
      {
        insertId: event.insert_id,
        timestamp: event.timestamp,

        userId: event.user.identifiers['$id'],
        identifiers: event.user.identifiers,
        userProperties: event.user.properties,
        hackleProperties: {},

        eventTypeId: event.event_type.id,
        eventTypeKey: event.event_type.key,
        value: event.event.value,
        properties: event.event.properties
      }
    end

    # @param event [RemoteConfigEvent]
    # @return [Hash]
    def remote_config_event(event)
      {
        insertId: event.insert_id,
        timestamp: event.timestamp,

        userId: event.user.identifiers['$id'],
        identifiers: event.user.identifiers,
        userProperties: event.user.properties,
        hackleProperties: {},

        parameterId: event.parameter.id,
        parameterKey: event.parameter.key,
        parameterType: event.parameter.type.name,
        valueId: event.value_id,
        decisionReason: event.decision_reason,
        properties: event.properties
      }
    end
  end
end

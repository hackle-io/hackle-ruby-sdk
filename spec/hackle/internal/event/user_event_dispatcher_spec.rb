# frozen_string_literal: true

require 'rspec'
require 'models'
require 'net/http'
require 'hackle/internal/event/user_event_dispatcher'

module Hackle
  RSpec.describe UserEventDispatcher do

    before do
      @http_client = double
      @serializer = double
      @sut = UserEventDispatcher.new(
        http_client: @http_client,
        executor: Executors.thread_pool(pool_size: 1, queue_capacity: 10),
        serializer: @serializer
      )
    end

    describe 'dispatch' do
      it 'success' do
        event = UserEvents.track(key: 'test')

        allow(@serializer).to receive(:serialize).and_return({ 'a' => 'b' })
        allow(@http_client).to receive(:execute).and_return(Net::HTTPResponse.new('1.1', '200', 'OK'))

        @sut.dispatch([event])
        @sut.shutdown

        expect(@serializer).to have_received(:serialize) do |events|
          expect(events.length).to eq(1)
          expect(events[0].event.key).to eq('test')
        end
        expect(@http_client).to have_received(:execute).exactly(1).times
        expect(@http_client).to have_received(:execute) do |request|
          expect(request.method).to eq('POST')
          expect(request.path).to eq('/api/v2/events')
          expect(request.body).to eq('{"a":"b"}')
        end
      end

      it 'failure' do
        event = UserEvents.track(key: 'test')

        allow(@serializer).to receive(:serialize).and_return({ 'a' => 'b' })
        allow(@http_client).to receive(:execute).and_return(Net::HTTPResponse.new('1.1', '500', 'error'))

        @sut.dispatch([event])
        @sut.shutdown
      end

      it 'posting fail' do
        executor = double
        sut = UserEventDispatcher.new(
          http_client: @http_client,
          executor: executor,
          serializer: @serializer
        )
        event = UserEvents.track(key: 'test')
        allow(@serializer).to receive(:serialize).and_return({ 'a' => 'b' })
        allow(@http_client).to receive(:execute).and_return(Net::HTTPResponse.new('1.1', '200', 'OK'))
        allow(executor).to receive(:post).and_raise(ArgumentError)

        sut.dispatch([event])

        expect(@http_client).to have_received(:execute).exactly(0).times
      end
    end

    describe 'shutdown' do
      it 'shutdown executor and wait' do
        executor = double
        sut = UserEventDispatcher.new(
          http_client: @http_client,
          executor: executor,
          serializer: @serializer
        )

        allow(executor).to receive(:shutdown).and_return(nil)
        allow(executor).to receive(:wait_for_termination).and_return(true)

        sut.shutdown

        expect(executor).to have_received(:shutdown).exactly(1).times
        expect(executor).to have_received(:wait_for_termination).with(10).exactly(1).times
      end

      it 'failed to wait' do
        executor = double
        sut = UserEventDispatcher.new(
          http_client: @http_client,
          executor: executor,
          serializer: @serializer
        )

        allow(executor).to receive(:shutdown).and_return(nil)
        allow(executor).to receive(:wait_for_termination).and_return(false)

        sut.shutdown

        expect(executor).to have_received(:shutdown).exactly(1).times
        expect(executor).to have_received(:wait_for_termination).with(10).exactly(1).times
      end
    end
  end

  RSpec.describe UserEventSerializer do

    it 'serialize' do
      sut = UserEventSerializer.new

      actual = sut.serialize(
        [
          ExposureEvent.new(
            insert_id: 'e1',
            timestamp: 42,
            user: HackleUser.builder
                            .identifier('$id', 'user')
                            .property('a', 1)
                            .build,
            experiment: Experiments.create(
              id: 100,
              key: 101,
              version: 5
            ),
            variation_id: 2001,
            variation_key: 'A',
            decision_reason: 'TRAFFIC_ALLOCATED',
            properties: { 'type' => 'exposure' }
          ),
          TrackEvent.new(
            insert_id: 't1',
            timestamp: 42,
            user: HackleUser.builder
                            .identifier('$id', 'user')
                            .property('a', 2)
                            .build,
            event_type: EventType.new(id: 1001, key: 'test'),
            event: Event.builder('test')
                        .value(42.0)
                        .property('type', 'track')
                        .build
          ),
          RemoteConfigEvent.new(
            insert_id: 'r1',
            timestamp: 42,
            user: HackleUser.builder
                            .identifier('$id', 'user')
                            .property('a', 3)
                            .build,
            parameter: RemoteConfigs.parameter(
              id: 2001,
              key: '2001_key',
              type: ValueType::STRING
            ),
            value_id: 1002,
            decision_reason: 'DEFAULT_RULE',
            properties: { 'type' => 'remote_config' }
          )
        ]
      )

      expect(actual).to eq({
                             exposureEvents: [
                               {
                                 insertId: 'e1',
                                 timestamp: 42,
                                 userId: 'user',
                                 identifiers: { '$id' => 'user' },
                                 userProperties: { 'a' => 1 },
                                 hackleProperties: {},
                                 experimentId: 100,
                                 experimentKey: 101,
                                 experimentType: 'AB_TEST',
                                 experimentVersion: 5,
                                 variationId: 2001,
                                 variationKey: 'A',
                                 decisionReason: 'TRAFFIC_ALLOCATED',
                                 properties: { 'type' => 'exposure' }
                               }],
                             trackEvents: [
                               {
                                 insertId: 't1',
                                 timestamp: 42,
                                 userId: 'user',
                                 identifiers: { '$id' => 'user' },
                                 userProperties: { 'a' => 2 },
                                 hackleProperties: {},
                                 eventTypeId: 1001,
                                 eventTypeKey: 'test',
                                 value: 42.0,
                                 properties: { 'type' => 'track' }
                               }
                             ],
                             remoteConfigEvents: [
                               {
                                 insertId: 'r1',
                                 timestamp: 42,
                                 userId: 'user',
                                 identifiers: { '$id' => 'user' },
                                 userProperties: { 'a' => 3 },
                                 hackleProperties: {},
                                 parameterId: 2001,
                                 parameterKey: '2001_key',
                                 parameterType: 'STRING',
                                 valueId: 1002,
                                 decisionReason: 'DEFAULT_RULE',
                                 properties: { 'type' => 'remote_config' }
                               }
                             ]
                           })
    end
  end
end


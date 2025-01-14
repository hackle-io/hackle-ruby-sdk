# frozen_string_literal: true

require 'rspec'
require 'models'
require 'concurrent'
require 'hackle/internal/event/user_event_processor'

module Hackle
  RSpec.describe UserEventProcessor do

    before do
      @event_dispatcher = double
      allow(@event_dispatcher).to receive(:dispatch).and_return(nil)
      allow(@event_dispatcher).to receive(:shutdown).and_return(nil)
    end

    def processor(
      queue: SizedQueue.new(10),
      event_dispatcher: @event_dispatcher,
      event_dispatch_size: 10,
      flush_scheduler: Executors.scheduler,
      flush_interval_seconds: 10.0,
      shutdown_timeout_seconds: 10.0
    )
      DefaultUserEventProcessor.new(
        queue: queue,
        event_dispatcher: event_dispatcher,
        event_dispatch_size: event_dispatch_size,
        flush_scheduler: flush_scheduler,
        flush_interval_seconds: flush_interval_seconds,
        shutdown_timeout_seconds: shutdown_timeout_seconds
      )
    end

    describe 'process' do
      it 'push event message in the queue' do
        queue = SizedQueue.new(1)
        sut = processor(queue: queue)

        expect(queue.length).to eq(0)

        event = UserEvent.new(insert_id: '42', timestamp: 42, user: HackleUser.builder.build)
        sut.process(event)

        expect(queue.length).to eq(1)

        expect(queue.pop.event).to be(event)
      end

      it 'when queue is full then ignore' do
        queue = SizedQueue.new(1)
        sut = processor(queue: queue)
        expect(queue.length).to eq(0)

        event = UserEvent.new(insert_id: '42', timestamp: 42, user: HackleUser.builder.build)
        sut.process(event)
        sut.process(event)
        sut.process(event)
        sut.process(event)

        expect(queue.length).to eq(1)
      end

      it 'when dispatch size not reached then do not dispatch' do
        sut = processor(event_dispatch_size: 2)
        sut.start

        event = UserEvent.new(insert_id: '42', timestamp: 42, user: HackleUser.builder.build)

        sut.process(event)
        sleep(0.1)

        expect(@event_dispatcher).to have_received(:dispatch).exactly(0).times

        sut.stop
      end

      it 'when dispatch size reached then dispatch event' do
        sut = processor(event_dispatch_size: 2)
        sut.start

        sut.process(UserEvents.track(key: '1'))
        sleep(0.1)
        expect(@event_dispatcher).to have_received(:dispatch).exactly(0).times

        sut.process(UserEvents.track(key: '2'))
        sleep(0.1)
        expect(@event_dispatcher).to have_received(:dispatch).exactly(1).times

        sut.stop
      end

      it 'when flush interval reached then dispatch events' do
        sut = processor(event_dispatch_size: 1000, flush_interval_seconds: 0.5)
        sut.start

        sut.process(UserEvents.track(key: '1'))
        sut.process(UserEvents.track(key: '2'))
        sut.process(UserEvents.track(key: '3'))
        sut.process(UserEvents.track(key: '4'))
        sut.process(UserEvents.track(key: '5'))
        sleep(1)

        expect(@event_dispatcher).to have_received(:dispatch).exactly(1).times

        sut.stop
      end

      it 'when event is empty then not dispatch' do
        sut = processor(event_dispatch_size: 1000, flush_interval_seconds: 0.1)
        sut.start

        sleep(1)

        expect(@event_dispatcher).to have_received(:dispatch).exactly(0).times

        sut.stop
      end
    end

    describe 'consuming' do

      it 'unsupported type' do
        queue = SizedQueue.new(10)
        sut = processor(queue: queue, event_dispatch_size: 1)
        sut.start
        queue.push('invalid')
        sut.process(UserEvents.track(key: '1'))
        sleep(0.1)

        expect(@event_dispatcher).to have_received(:dispatch).exactly(1).times

        sut.stop
      end

      it 'error on consuming' do
        queue = SizedQueue.new(10)
        allow(@event_dispatcher).to receive(:dispatch).and_raise(ArgumentError)

        sut = processor(queue: queue, event_dispatch_size: 1)
        sut.start

        sut.process(UserEvents.track(key: '1'))
        sleep(0.1)
        expect(@event_dispatcher).to have_received(:dispatch).exactly(1).times

        sut.process(UserEvents.track(key: '1'))
        sleep(0.1)
        expect(@event_dispatcher).to have_received(:dispatch).exactly(2).times

        sut.stop
      end
    end

    describe 'start' do
      it 'start once' do
        scheduler = double
        allow(scheduler).to receive(:schedule_periodically).and_return(double)
        sut = processor(flush_scheduler: scheduler)

        sut.start
        sut.start
        sut.start

        expect(scheduler).to have_received(:schedule_periodically).exactly(1).times
      end
    end

    describe 'stop' do
      it 'cancel flushing' do
        scheduler = double
        job = double
        allow(scheduler).to receive(:schedule_periodically).and_return(job)
        allow(job).to receive(:cancel).and_return(true)

        sut = processor(flush_scheduler: scheduler)

        sut.start
        expect(job).to have_received(:cancel).exactly(0).times

        sut.stop
        expect(job).to have_received(:cancel).exactly(1).times
      end

      it 'shutdown consuming' do
        sut = processor(flush_interval_seconds: 10)
        sut.start

        sut.process(UserEvents.track(key: '1'))
        sut.stop

        sleep(0.1)

        expect(@event_dispatcher).to have_received(:dispatch).exactly(1).times
      end

      it 'shutdown dispatcher' do
        sut = processor

        sut.start
        expect(@event_dispatcher).to have_received(:shutdown).exactly(0).times

        sut.stop
        expect(@event_dispatcher).to have_received(:shutdown).exactly(1).times
      end

      it 'not started' do
        sut = processor
        sut.stop
        expect(@event_dispatcher).to have_received(:shutdown).exactly(0).times
      end
    end

    describe 'resume' do
      it 'when consuming task is nil then start consuming' do
        q = SizedQueue.new(10)
        sut = processor(queue: q)

        sut.resume
        sut.process(UserEvents.track(key: '1'))

        sleep(0.1)
        expect(q.length).to eq(0)

        sut.stop
      end

      it 'when consuming task is not alive then start consuming' do
        q = SizedQueue.new(10)
        sut = processor(queue: q)
        sut.start
        sut.stop

        sut.resume
        sut.process(UserEvents.track(key: '1'))

        sleep(0.1)
        expect(q.length).to eq(0)

        sut.stop
      end

      it 'reschedule flush' do
        q = SizedQueue.new(10)
        allow(q).to receive(:push).and_call_original
        sut = processor(queue: q, flush_interval_seconds: 0.5)
        sut.start

        sleep(0.8)
        expect(q).to have_received(:push).exactly(1).times

        sut.resume
        sleep(0.8)
        expect(q).to have_received(:push).exactly(2).times
      end

      it 'fork consume' do
        q = SizedQueue.new(10)
        sut = processor(queue: q, event_dispatch_size: 1)
        sut.start

        fork do
          sut.resume
          sut.process(UserEvents.track(key: '1'))
          sut.process(UserEvents.track(key: '2'))
          sleep(0.1)
          expect(@event_dispatcher).to have_received(:dispatch).exactly(2).times
          sut.stop
        end

        sut.process(UserEvents.track(key: '1'))
        sut.process(UserEvents.track(key: '2'))
        sleep(0.1)
        expect(@event_dispatcher).to have_received(:dispatch).exactly(2).times
        sut.stop
      end

      it 'fork flush' do
        q = SizedQueue.new(10)
        allow(q).to receive(:push).and_call_original
        sut = processor(queue: q, event_dispatch_size: 1, flush_interval_seconds: 0.2)
        sut.start

        fork do
          sut.resume
          sleep(0.5)
          expect(q).to have_received(:push).exactly(2).times

          sut.stop
        end

        sleep(0.5)
        expect(q).to have_received(:push).exactly(2).times

        sut.stop
      end
    end
  end
end

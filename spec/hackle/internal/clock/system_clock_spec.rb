# frozen_string_literal: true

require 'rspec'
require 'hackle/internal/clock/clock'

module Hackle
  describe SystemClock do

    context 'system' do
      it 'current_millis' do
        clock = SystemClock.instance
        s = clock.current_millis
        sleep 0.5
        e = clock.current_millis
        expect(e - s).to be_within(5).of(500)
      end

      it 'tick' do
        clock = SystemClock.instance
        s = clock.tick
        sleep 0.5
        e = clock.tick
        expect(e - s).to be_within(5_000_000).of(500_000_000)
      end
    end

    it 'fixed' do
      clock = FixedClock.new(42)
      expect(clock.current_millis).to eq(42)
      expect(clock.tick).to eq(42)
    end
  end
end

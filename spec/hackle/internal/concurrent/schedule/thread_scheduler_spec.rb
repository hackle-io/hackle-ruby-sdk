# frozen_string_literal: true

require 'rspec'
require 'hackle/internal/concurrent/schedule/timer_scheduler'
require 'hackle/internal/logger/logger'

module Hackle
  RSpec.describe TimerScheduler do

    it 'schedule' do
      count = 0
      scheduler = TimerScheduler.new
      job = scheduler.schedule_periodically(0.1, -> { count += 1 })
      sleep 0.55
      job.cancel
      expect(count).to eq(5)
    end

    it 'cancel during delay' do
      count = 0
      scheduler = TimerScheduler.new
      job = scheduler.schedule_periodically(0.5, -> { count += 1 })
      sleep 0.1
      job.cancel
      expect(count).to eq(0)
    end

    it 'long task' do
      count = 0
      scheduler = TimerScheduler.new
      job = scheduler.schedule_periodically(0.1, lambda {
        sleep 0.4
        count += 1
      })
      sleep 1
      job.cancel
      expect(count).to eq(2)
    end
  end
end

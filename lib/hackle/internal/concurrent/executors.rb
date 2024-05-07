# frozen_string_literal: true

require 'concurrent'
require 'hackle/internal/concurrent/schedule/timer_scheduler'

module Hackle
  class Executors
    # @param pool_size [Integer]
    # @param queue_capacity [Integer]
    # @return [Concurrent::ThreadPoolExecutor]
    def self.thread_pool(pool_size:, queue_capacity:)
      Concurrent::ThreadPoolExecutor.new(min_threads: pool_size, max_threads: pool_size, max_queue: queue_capacity)
    end

    # @return [TimerScheduler]
    def self.scheduler
      TimerScheduler.new
    end
  end
end

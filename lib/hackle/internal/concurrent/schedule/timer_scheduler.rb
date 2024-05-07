# frozen_string_literal: true

require 'concurrent'
require 'hackle/internal/concurrent/schedule/scheduler'

module Hackle
  class TimerScheduler
    include Scheduler

    def schedule_periodically(interval_seconds, task)
      timer_task = Concurrent::TimerTask.new(execution_interval: interval_seconds, interval_type: :fixed_rate) do
        task.call
      end
      timer_task.execute
      TimerScheduledJob.new(timer_task)
    end
  end

  class TimerScheduledJob
    include ScheduledJob

    def initialize(task)
      @task = task
    end

    def cancel
      @task.shutdown
    end
  end
end

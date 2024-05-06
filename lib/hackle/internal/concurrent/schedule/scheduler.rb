# frozen_string_literal: true

module Hackle
  module Scheduler
    def schedule_periodically(interval_seconds, task) end
  end

  module ScheduledJob
    def cancel
    end
  end
end

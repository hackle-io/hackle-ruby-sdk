# frozen_string_literal: true

module Hackle
  module Clock
    # @return [Integer]
    def current_millis; end

    # @return [Integer]
    def tick; end
  end

  class SystemClock
    include Clock

    @instance = new

    # @return [SystemClock]
    def self.instance
      @instance
    end

    def current_millis
      (Time.now.to_f * 1000).to_i
    end

    def tick
      (Time.now.to_f * 1000 * 1000 * 1000).to_i
    end
  end

  class FixedClock
    include Clock

    # @param time [Integer]
    def initialize(time)
      @time = time
    end

    def current_millis
      @time
    end

    def tick
      @time
    end
  end
end

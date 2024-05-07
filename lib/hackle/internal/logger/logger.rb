# frozen_string_literal: true

require 'logger'

module Hackle

  class Log

    attr_accessor :logger

    def initialize
      @logger = Logger.new($stdout)
    end

    @instance = new

    # @return [Log]
    def self.instance
      @instance
    end

    def self.init(logger)
      instance.logger = logger
    end

    # @return [Logger]
    def self.get
      Log.instance.logger
    end
  end
end

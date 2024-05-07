# frozen_string_literal: true

require 'logger'

module Hackle
  class Config
    # @return [Logger]
    attr_reader :logger

    # @return [String]
    attr_reader :sdk_url

    # @return [String]
    attr_reader :event_url

    # @param logger [Logger]
    # @param sdk_url [String]
    # @param event_url [String]
    def initialize(
      logger:,
      sdk_url:,
      event_url:
    )
      @logger = logger
      @sdk_url = sdk_url
      @event_url = event_url
    end

    def self.builder
      Builder.new
    end

    class Builder
      def initialize
        # noinspection RubyResolve
        @logger = if defined?(Rails) && Rails.logger
                    Rails.logger
                  else
                    Logger.new($stdout)
                  end
        @sdk_url = 'https://sdk.hackle.io'
        @event_url = 'https://event.hackle.io'
      end

      # @param logger [Logger]
      # @return [Hackle::Config::Builder]
      def logger(logger)
        @logger = logger
        self
      end

      # @param sdk_url [String]
      # @return [Hackle::Config::Builder]
      def sdk_url(sdk_url)
        @sdk_url = sdk_url
        self
      end

      # @param event_url [String]
      # @return [Hackle::Config::Builder]
      def event_url(event_url)
        @event_url = event_url
        self
      end

      # @return [Hackle::Config]
      def build
        Config.new(
          logger: @logger,
          sdk_url: @sdk_url,
          event_url: @event_url
        )
      end
    end
  end
end

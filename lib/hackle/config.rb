# frozen_string_literal: true

require 'logger'

module Hackle
  class Config

    def initialize(options = {})
      @logger = options[:logger] || Config.default_logger
      @base_uri = options[:base_uri] || Config.default_base_uri
      @event_uri = options[:event_uri] || Config.default_event_uri
    end

    attr_reader :logger
    attr_reader :base_uri
    attr_reader :event_uri

    def self.default_base_uri
      'https://sdk.hackle.io'
    end

    def self.default_event_uri
      'https://event.hackle.io'
    end

    def self.default_logger
      if defined?(Rails) && Rails.logger
        Rails.logger
      else
        Logger.new($stdout)
      end
    end
  end
end

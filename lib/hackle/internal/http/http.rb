# frozen_string_literal: true

require 'net/http'

module Hackle
  module HTTP

    def self.client(base_url:)
      uri = URI.parse(base_url)
      # noinspection RubyMismatchedArgumentType
      client = Net::HTTP.new(uri.host, uri.port)
      client.use_ssl = uri.scheme == 'https'
      client.open_timeout = 5
      client.read_timeout = 10
      client
    end

    # @param response [Net::HTTPResponse]
    def self.successful?(response)
      response.code.start_with?('2')
    end

    # @param response [Net::HTTPResponse]
    def self.not_modified?(response)
      response.code == '304'
    end
  end
end

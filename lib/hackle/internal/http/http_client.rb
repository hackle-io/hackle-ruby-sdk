# frozen_string_literal: true

require 'hackle/internal/http/http'
require 'hackle/internal/clock/clock'

module Hackle
  class HttpClient

    # @param http [Net::HTTP]
    # @param sdk [Sdk]
    # @param clock [Clock]
    def initialize(http:, sdk:, clock:)
      # @type [Net::HTTP]
      @http = http
      @sdk = sdk
      @clock = clock
    end

    # @param base_url [String]
    # @param sdk [Sdk]
    # @param clock [Clock]
    # @return [HttpClient]
    def self.create(base_url:, sdk:, clock: SystemClock.instance)
      HttpClient.new(
        http: HTTP.client(base_url: base_url),
        sdk: sdk,
        clock: clock
      )
    end

    # @param request [Net::HTTPRequest]
    # @return [Net::HTTPResponse]
    def execute(request)
      decorate(request)
      @http.request(request)
    end

    private

    # @param request [Net::HTTPRequest]
    def decorate(request)
      request['X-HACKLE-SDK-KEY'] = @sdk.key
      request['X-HACKLE-SDK-NAME'] = @sdk.name
      request['X-HACKLE-SDK-VERSION'] = @sdk.version
      request['X-HACKLE-SDK-TIME'] = @clock.current_millis.to_s
    end
  end
end

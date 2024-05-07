# frozen_string_literal: true

require 'json'
require 'hackle/internal/http/http'
require 'hackle/internal/workspace/workspace'

module Hackle
  class HttpWorkspaceFetcher
    # @param http_client [HttpClient]
    # @param sdk [Sdk]
    def initialize(http_client:, sdk:)

      # @type [String]
      @url = "/api/v2/workspaces/#{sdk.key}/config"

      # @type [HttpClient]
      @http_client = http_client

      # @type [String, nil]
      @last_modified = nil
    end

    # @return [Hackle::Workspace, nil]
    def fetch_if_modified
      request = create_request
      response = @http_client.execute(request)
      handle_response(response)
    end

    private

    # @return [Net::HTTPRequest]
    def create_request
      request = Net::HTTP::Get.new(@url)
      request['If-Modified-Since'] = @last_modified unless @last_modified.nil?
      request
    end

    # @param response [Net::HTTPResponse]
    # @return [Workspace, nil]
    def handle_response(response)
      return nil if HTTP.not_modified?(response)
      raise "http status code: #{response.code}" unless HTTP.successful?(response)

      @last_modified = response.header['Last-Modified']
      response_body = JSON.parse(response.body, symbolize_names: true)
      Workspace.from_hash(response_body)
    end
  end
end

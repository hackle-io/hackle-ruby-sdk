# frozen_string_literal: true

require 'json'

module Hackle
  class HttpWorkspaceFetcher

    def initialize(config:, sdk_info:)
      @client = HTTP.client(base_uri: config.base_uri)
      @headers = HTTP.sdk_headers(sdk_info: sdk_info)
    end

    def fetch
      request = Net::HTTP::Get.new('/api/v1/workspaces', @headers)
      response = @client.request(request)

      status_code = response.code.to_i
      HTTP.check_successful(status_code: status_code)

      response_body = JSON.parse(response.body, symbolize_names: true)
      Workspace.create(data: response_body)
    end
  end
end

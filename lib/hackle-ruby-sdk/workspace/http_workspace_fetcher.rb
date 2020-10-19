require 'json'

module Hackle
  class HttpWorkspaceFetcher

    def initialize(config, sdk_info)
      @client = HTTP.client(config.base_uri)
      @headers = HTTP.sdk_headers(sdk_info)
    end

    def fetch
      request = Net::HTTP::Get.new('/api/v1/workspaces', @headers)
      response = @client.request(request)

      status_code = response.code.to_i
      HTTP.check_successful(status_code)

      data = JSON.parse(response.body, symbolize_names: true)
      Workspace.create(data)
    end
  end
end

require 'net/http'

module Hackle
  class UnexpectedResponseError < StandardError

    def initialize(status_code)
      super("HTTP status code #{status_code}")
    end
  end

  class HTTP
    def self.client(base_uri)
      uri = URI.parse(base_uri)
      client = Net::HTTP.new(uri.host, uri.port)
      client.use_ssl = uri.scheme == 'https'
      client.open_timeout = 5
      client.read_timeout = 10
      client
    end

    def self.sdk_headers(sdk_info)
      {
        'X-HACKLE-SDK-KEY' => sdk_info.key,
        'X-HACKLE-SDK-NAME' => sdk_info.name,
        'X-HACKLE-SDK-VERSION' => sdk_info.version
      }
    end

    def self.successful?(status_code)
      status_code >= 200 && status_code < 300
    end

    def self.check_successful(status_code)
      raise UnexpectedResponseError.new(status_code) unless successful?(status_code)
    end
  end
end

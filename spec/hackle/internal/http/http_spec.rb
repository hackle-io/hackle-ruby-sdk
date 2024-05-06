# frozen_string_literal: true

require 'rspec'
require 'models'
require 'hackle/internal/http/http'

module Hackle
  describe HTTP do

    it 'client' do
      client = HTTP.client(base_url: 'http://localhost')

      expect(client.address).to eq('localhost')
      expect(client.port).to eq(80)
      expect(client.use_ssl?).to eq(false)
      expect(client.open_timeout).to eq(5)
      expect(client.read_timeout).to eq(10)
    end

    it 'successful' do
      expect(HTTP.successful?(Net::HTTPResponse.new('1.1', '200', 'OK'))).to eq(true)
      expect(HTTP.successful?(Net::HTTPResponse.new('1.1', '500', 'ERROR'))).to eq(false)
    end

    it 'not_modified?' do
      expect(HTTP.not_modified?(Net::HTTPResponse.new('1.1', '304', 'NOT_MODIFIED'))).to eq(true)
      expect(HTTP.not_modified?(Net::HTTPResponse.new('1.1', '200', 'OK'))).to eq(false)
    end
  end
end

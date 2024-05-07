# frozen_string_literal: true

require 'rspec'
require 'models'
require 'hackle/internal/workspace/http_workspace_fetcher'

module Hackle
  RSpec.describe HttpWorkspaceFetcher do

    before do
      @http_client = double
      @sdk = Sdk.new(name: 'sdk_name', version: 'sdk_version', key: 'sdk_key')
      @sut = HttpWorkspaceFetcher.new(http_client: @http_client, sdk: @sdk)
    end

    it 'when workspace not modified then return nil' do
      allow(@http_client).to receive(:execute).and_return(Net::HTTPResponse.new('1.1', '304', 'NOT_MODIFIED'))

      actual = @sut.fetch_if_modified

      expect(actual).to eq(nil)
    end

    it 'when http not successful then raise error' do
      allow(@http_client).to receive(:execute).and_return(Net::HTTPResponse.new('1.1', '500', 'ERROR'))

      expect { @sut.fetch_if_modified }.to raise_error('http status code: 500')
    end

    it 'when success to get workspace then return workspace' do
      json = File.read('spec/data/workspace_config.json')
      response = instance_double(Net::HTTPResponse, code: '200', body: json, header: {})
      allow(@http_client).to receive(:execute).and_return(response)

      actual = @sut.fetch_if_modified

      expect(actual).not_to eq(nil)
    end

    it 'when Last-Modified header is exist then execute with header' do
      json = File.read('spec/data/workspace_config.json')
      response = instance_double(Net::HTTPResponse, code: '200', body: json, header: { 'Last-Modified' => 'LAST_MODIFIED_HEADER_VALUE' })
      http_client = MockHttpClient.new(response)
      sut = HttpWorkspaceFetcher.new(http_client: http_client, sdk: @sdk)

      sut.fetch_if_modified
      expect(http_client.requests[0]['If-Modified-Since']).to be_nil
      expect(http_client.requests[0].path).to eq('/api/v2/workspaces/sdk_key/config')

      sut.fetch_if_modified
      expect(http_client.requests[1]['If-Modified-Since']).to eq('LAST_MODIFIED_HEADER_VALUE')

    end
  end

  class MockHttpClient

    attr_reader :requests

    def initialize(response)
      @response = response
      @requests = []
    end

    def execute(request)
      @requests << request
      @response
    end
  end
end

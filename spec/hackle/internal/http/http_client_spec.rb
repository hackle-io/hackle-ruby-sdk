# frozen_string_literal: true

require 'rspec'
require 'models'
require 'hackle/internal/http/http_client'

module Hackle
  RSpec.describe HttpClient do

    it 'decorate' do
      http = double
      sdk = Sdk.new(name: 'sdk_name', version: 'sdk_version', key: 'sdk_key')
      clock = FixedClock.new(42)

      sut = HttpClient.new(http: http, sdk: sdk, clock: clock)

      request = Net::HTTP::Get.new('localhost')
      response = double
      allow(http).to receive(:request).and_return(response)

      actual = sut.execute(request)
      expect(actual).to eq(response)

      expect(http).to have_received(:request) do |r|
        expect(r['X-HACKLE-SDK-KEY']).to eq('sdk_key')
        expect(r['X-HACKLE-SDK-NAME']).to eq('sdk_name')
        expect(r['X-HACKLE-SDK-VERSION']).to eq('sdk_version')
        expect(r['X-HACKLE-SDK-TIME']).to eq('42')
      end
    end
  end
end

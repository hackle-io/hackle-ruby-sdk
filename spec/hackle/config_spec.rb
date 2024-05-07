# frozen_string_literal: true

require 'rspec'
require 'models'
require 'hackle/config'

module Hackle
  RSpec.describe Config do

    it 'build' do
      logger = double
      config = Config.builder
                     .logger(logger)
                     .sdk_url('sdk')
                     .event_url('event')
                     .build

      expect(config.logger).to eq(logger)
      expect(config.sdk_url).to eq('sdk')
      expect(config.event_url).to eq('event')
    end
  end
end

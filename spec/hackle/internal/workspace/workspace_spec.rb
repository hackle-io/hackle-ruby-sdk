# frozen_string_literal: true

require 'rspec'
require 'models'
require 'json'
require 'hackle/internal/workspace/workspace'

module Hackle
  RSpec.describe Workspace do

    it 'create' do
      json = File.read('spec/data/workspace_config.json')
      hash = JSON.parse(json, symbolize_names: true)
      workspace = Workspace.from_hash(hash)

      expect(workspace.get_experiment_or_nil(4)).to be_nil

      expect(workspace.get_experiment_or_nil(5))
    end
  end
end


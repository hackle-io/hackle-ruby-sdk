# frozen_string_literal: true

require 'rspec'
require 'models'
require 'hackle/internal/evaluation/evaluator/experiment/experiment_resolver'

module Hackle
  RSpec.describe ExperimentTargetDeterminer do
    before do
      @target_matcher = double
      @sut = ExperimentTargetDeterminer.new(target_matcher: @target_matcher)
    end

    it 'when audiences is empty then return true' do
      request = Experiments.request(experiment: Experiments.create(target_audiences: []))
      context = Evaluator.context

      expect(@sut.user_in_experiment_target?(request, context)).to eq(true)
    end

    it 'when any of audience match then return true' do
      target = Target.new(conditions: [])
      request = Experiments.request(
        experiment: Experiments.create(target_audiences: [target, target, target, target, target])
      )
      context = Evaluator.context

      allow(@target_matcher).to receive(:matches).and_return(false, false, false, true, false)

      expect(@sut.user_in_experiment_target?(request, context)).to eq(true)
      expect(@target_matcher).to have_received(:matches).exactly(4).times
    end

    it 'when all audiences do not match then return false' do
      target = Target.new(conditions: [])
      request = Experiments.request(
        experiment: Experiments.create(target_audiences: [target, target, target, target, target])
      )
      context = Evaluator.context

      allow(@target_matcher).to receive(:matches).and_return(false, false, false, false, false)

      expect(@sut.user_in_experiment_target?(request, context)).to eq(false)
      expect(@target_matcher).to have_received(:matches).exactly(5).times
    end
  end
end

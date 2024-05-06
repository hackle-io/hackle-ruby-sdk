# frozen_string_literal: true

require 'rspec'
require 'hackle/internal/evaluation/match/target/target_matcher'
require 'models'

module Hackle
  describe TargetMatcher do
    before do
      @condition_matcher = double
      @condition_matcher_factory = double
      allow(@condition_matcher_factory).to receive(:get).with(anything).and_return(@condition_matcher)
      @sut = TargetMatcher.new(condition_matcher_factory: @condition_matcher_factory)
    end

    it 'when condition is empty then return true' do
      request = Experiments.request
      context = Evaluator.context
      target = Target.new(conditions: [])

      expect(@sut.matches(request, context, target)).to be(true)
    end

    it 'when any of condition not matched then return false' do
      allow(@condition_matcher).to receive(:matches).with(anything, anything, anything)
                                                    .and_return(true, true, true, false, true)

      request = Experiments.request
      context = Evaluator.context
      condition = TargetCondition.new(key: TargetKey.new(type: TargetKeyType::USER_PROPERTY, name: 'name'), match: double)
      target = Target.new(conditions: [condition, condition, condition, condition, condition])

      expect(@sut.matches(request, context, target)).to be(false)
      expect(@condition_matcher).to have_received(:matches).exactly(4).times
    end

    it 'when all condition matched then return true' do
      allow(@condition_matcher).to receive(:matches).with(anything, anything, anything)
                                                    .and_return(true, true, true, true, true)

      request = Experiments.request
      context = Evaluator.context
      condition = TargetCondition.new(key: TargetKey.new(type: TargetKeyType::USER_PROPERTY, name: 'name'), match: double)
      target = Target.new(conditions: [condition, condition, condition, condition, condition])

      expect(@sut.matches(request, context, target)).to be(true)
      expect(@condition_matcher).to have_received(:matches).exactly(5).times
    end
  end
end

# frozen_string_literal: true

require 'rspec'
require 'models'
require 'hackle/internal/evaluation/match/condition/experiment/experiment_condition_matcher'

module Hackle
  describe ExperimentConditionMatcher do

    it 'matches' do
      ab_test_matcher = double
      feature_flag_matcher = double
      allow(ab_test_matcher).to receive(:matches).and_return(true)
      allow(feature_flag_matcher).to receive(:matches).and_return(false)
      sut = ExperimentConditionMatcher.new(
        ab_test_matcher: ab_test_matcher,
        feature_flag_matcher: feature_flag_matcher
      )

      condition = TargetCondition.new(key: TargetKey.new(type: TargetKeyType::AB_TEST, name: '42'), match: double)
      expect(sut.matches(Experiments.request, Evaluator.context, condition)).to eq(true)

      condition = TargetCondition.new(key: TargetKey.new(type: TargetKeyType::FEATURE_FLAG, name: '42'), match: double)
      expect(sut.matches(Experiments.request, Evaluator.context, condition)).to eq(false)

      condition = TargetCondition.new(key: TargetKey.new(type: TargetKeyType.new('INVALID'), name: '42'), match: double)
      expect { sut.matches(Experiments.request, Evaluator.context, condition) }.to raise_error(ArgumentError, 'unsupported TargetKeyType [INVALID]')
    end
  end
end

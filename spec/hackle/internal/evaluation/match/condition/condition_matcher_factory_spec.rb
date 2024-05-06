# frozen_string_literal: true

require 'rspec'
require 'models'
require 'hackle/internal/evaluation/match/condition/condition_matcher_factory'

module Hackle
  describe ConditionMatcherFactory do

    it 'get' do
      factory = ConditionMatcherFactory.new(evaluator: double)
      expect(factory.get(TargetKeyType::USER_ID)).to be_a(UserConditionMatcher)
      expect(factory.get(TargetKeyType::USER_PROPERTY)).to be_a(UserConditionMatcher)
      expect(factory.get(TargetKeyType::HACKLE_PROPERTY)).to be_a(UserConditionMatcher)
      expect(factory.get(TargetKeyType::SEGMENT)).to be_a(SegmentConditionMatcher)
      expect(factory.get(TargetKeyType::AB_TEST)).to be_a(ExperimentConditionMatcher)
      expect(factory.get(TargetKeyType::FEATURE_FLAG)).to be_a(ExperimentConditionMatcher)
      expect { factory.get(TargetKeyType.new('INVALID')) }.to raise_error(ArgumentError)
    end
  end
end

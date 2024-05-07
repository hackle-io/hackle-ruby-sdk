# frozen_string_literal: true

require 'hackle/internal/evaluation/match/value/value_operator_matcher'
require 'hackle/internal/evaluation/match/value/value_matcher_factory'
require 'hackle/internal/evaluation/match/operator/operator_matcher_factory'
require 'hackle/internal/evaluation/match/condition/user/user_condition_matcher'
require 'hackle/internal/evaluation/match/condition/segment/segment_condition_matcher'
require 'hackle/internal/evaluation/match/condition/experiment/experiment_condition_matcher'
require 'hackle/internal/evaluation/match/condition/experiment/experiment_evaluator_matcher'

module Hackle
  class ConditionMatcherFactory
    # @param evaluator [Evaluator]
    def initialize(evaluator:)
      value_operator_matcher = ValueOperatorMatcher.new(
        value_matcher_factory: ValueMatcherFactory.new,
        operator_matcher_factory: OperatorMatcherFactory.new
      )
      @user_condition_matcher = UserConditionMatcher.new(
        user_value_resolver: UserValueResolver.new,
        value_operator_matcher: value_operator_matcher
      )
      @segment_condition_matcher = SegmentConditionMatcher.new(
        segment_matcher: SegmentMatcher.new(user_condition_matcher: @user_condition_matcher)
      )
      @experiment_condition_matcher = ExperimentConditionMatcher.new(
        ab_test_matcher: AbTestEvaluatorMatcher.new(
          evaluator: evaluator,
          value_operator_matcher: value_operator_matcher
        ),
        feature_flag_matcher: FeatureFlagEvaluatorMatcher.new(
          evaluator: evaluator,
          value_operator_matcher: value_operator_matcher
        )
      )
    end

    # @param key_type [TargetKeyType]
    # @return [ConditionMatcher]
    def get(key_type)
      case key_type
      when TargetKeyType::USER_ID, TargetKeyType::USER_PROPERTY, TargetKeyType::HACKLE_PROPERTY
        @user_condition_matcher
      when TargetKeyType::SEGMENT
        @segment_condition_matcher
      when TargetKeyType::AB_TEST, TargetKeyType::FEATURE_FLAG
        @experiment_condition_matcher
      else
        raise ArgumentError, "unsupported TargetKeyType [#{key_type}]"
      end
    end
  end
end

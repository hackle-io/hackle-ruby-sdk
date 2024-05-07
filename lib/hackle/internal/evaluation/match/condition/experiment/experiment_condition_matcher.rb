# frozen_string_literal: true

require 'hackle/internal/evaluation/match/condition/condition_matcher'

module Hackle
  class ExperimentConditionMatcher
    include ConditionMatcher

    # @param ab_test_matcher [ExperimentEvaluatorMatcher]
    # @param feature_flag_matcher [ExperimentEvaluatorMatcher]
    def initialize(ab_test_matcher:, feature_flag_matcher:)
      # @type [ExperimentEvaluatorMatcher]
      @ab_test_matcher = ab_test_matcher
      # @type [ExperimentEvaluatorMatcher]
      @feature_flag_matcher = feature_flag_matcher
    end

    def matches(request, context, condition)
      case condition.key.type
      when TargetKeyType::AB_TEST
        @ab_test_matcher.matches(request, context, condition)
      when TargetKeyType::FEATURE_FLAG
        @feature_flag_matcher.matches(request, context, condition)
      else
        raise ArgumentError, "unsupported TargetKeyType [#{condition.key.type}]"
      end
    end
  end
end

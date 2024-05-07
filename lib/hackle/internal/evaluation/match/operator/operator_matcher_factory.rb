# frozen_string_literal: true

require 'hackle/internal/model/target'
require 'hackle/internal/evaluation/match/operator/operator_matcher'

module Hackle
  class OperatorMatcherFactory

    def initialize
      @matchers = {
        TargetOperator::IN => InMatcher.new,
        TargetOperator::CONTAINS => ContainsMatcher.new,
        TargetOperator::STARTS_WITH => StartsWithMatcher.new,
        TargetOperator::ENDS_WITH => EndsWithMatcher.new,
        TargetOperator::GT => GreaterThanMatcher.new,
        TargetOperator::GTE => GreaterThanOrEqualToMatcher.new,
        TargetOperator::LT => LessThanMatcher.new,
        TargetOperator::LTE => LessThanOrEqualToMatcher.new
      }.freeze
    end

    # @param operator [TargetOperator]
    # @return [OperatorMatcher]
    def get(operator)
      matcher = @matchers[operator]
      raise ArgumentError, "Unsupported TargetOperator [#{operator}]" unless matcher

      matcher
    end
  end
end

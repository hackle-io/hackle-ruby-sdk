# frozen_string_literal: true

require 'hackle/internal/model/target'

module Hackle
  class ValueOperatorMatcher
    # @param value_matcher_factory [ValueMatcherFactory]
    # @param operator_matcher_factory [OperatorMatcherFactory]
    def initialize(value_matcher_factory:, operator_matcher_factory:)
      # @type [ValueMatcherFactory]
      @value_matcher_factory = value_matcher_factory
      # @type [OperatorMatcherFactory]
      @operator_matcher_factory = operator_matcher_factory
    end

    # @param value [Object]
    # @param match [TargetMatch]
    # @return [boolean]
    def matches(value, match)
      value_matcher = @value_matcher_factory.get(match.value_type)
      operator_matcher = @operator_matcher_factory.get(match.operator)

      matches = internal_matches(value, match, value_matcher, operator_matcher)
      TargetMatchType.matches(match.type, matches)
    end

    private

    # @param value [Object]
    # @param match [TargetMatch]
    # @param value_matcher [ValueMatcher]
    # @param operator_matcher [OperatorMatcher]
    # @return [boolean]
    def internal_matches(value, match, value_matcher, operator_matcher)
      # noinspection RubyMismatchedArgumentType
      return array_matches(value, match, value_matcher, operator_matcher) if value.is_a?(Array)

      single_matches(value, match, value_matcher, operator_matcher)
    end

    # @param value [Object]
    # @param match [TargetMatch]
    # @param value_matcher [ValueMatcher]
    # @param operator_matcher [OperatorMatcher]
    # @return [boolean]
    def single_matches(value, match, value_matcher, operator_matcher)
      match.values.any? { |it| value_matcher.matches(operator_matcher, value, it) }
    end

    # @param values [Array<Object>]
    # @param match [TargetMatch]
    # @param value_matcher [ValueMatcher]
    # @param operator_matcher [OperatorMatcher]
    # @return [boolean]
    def array_matches(values, match, value_matcher, operator_matcher)
      values.any? { |it| single_matches(it, match, value_matcher, operator_matcher) }
    end
  end
end

# frozen_string_literal: true

require 'hackle/internal/model/version'

module Hackle
  module ValueMatcher
    # @param operator_matcher [OperatorMatcher]
    # @param value [Object]
    # @param match_value [Object]
    # @return [boolean]
    def matches(operator_matcher, value, match_value) end
  end

  class StringMatcher
    include ValueMatcher

    def matches(operator_matcher, value, match_value)
      type_value = as_string(value)
      type_match_value = as_string(match_value)
      return false if type_value.nil? || type_match_value.nil?

      operator_matcher.string_matches(type_value, type_match_value)
    end

    private

    # @param value [Object]
    # @return [String, nil]
    # noinspection RubyMismatchedReturnType
    def as_string(value)
      return value if value.is_a?(String)
      return value.to_s if value.is_a?(Numeric)

      nil
    end
  end

  class NumberMatcher
    include ValueMatcher

    def matches(operator_matcher, value, match_value)
      type_value = as_number(value)
      type_match_value = as_number(match_value)
      return false if type_value.nil? || type_match_value.nil?

      operator_matcher.number_matches(type_value, type_match_value)
    end

    private

    # @param value [Object]
    # @return [Numeric, nil]
    # noinspection RubyMismatchedReturnType
    def as_number(value)
      return value if value.is_a?(Numeric)
      return Float(value, exception: false) if value.is_a?(String)

      nil
    end
  end

  class BooleanMatcher
    include ValueMatcher

    def matches(operator_matcher, value, match_value)
      type_value = as_boolean(value)
      type_match_value = as_boolean(match_value)
      return false if type_value.nil? || type_match_value.nil?

      operator_matcher.boolean_matches(type_value, type_match_value)
    end

    private

    # @param value [Object]
    # @return [boolean, nil]
    def as_boolean(value)
      return true if value.is_a?(TrueClass)
      return false if value.is_a?(FalseClass)

      nil
    end
  end

  class VersionMatcher
    include ValueMatcher

    def matches(operator_matcher, value, match_value)
      type_value = Version.parse_or_nil(value)
      type_match_value = Version.parse_or_nil(match_value)
      return false if type_value.nil? || type_match_value.nil?

      operator_matcher.version_matches(type_value, type_match_value)
    end
  end
end

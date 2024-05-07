# frozen_string_literal: true

module Hackle
  module OperatorMatcher
    # @param value [String]
    # @param match_value [String]
    # @return [boolean]
    def string_matches(value, match_value) end

    # @param value [Numeric]
    # @param match_value [Numeric]
    # @return [boolean]
    def number_matches(value, match_value) end

    # @param value [boolean]
    # @param match_value [boolean]
    # @return [boolean]
    def boolean_matches(value, match_value) end

    # @param value [Version]
    # @param match_value [Version]
    # @return [boolean]
    def version_matches(value, match_value) end
  end

  class InMatcher
    include OperatorMatcher

    def string_matches(value, match_value)
      value == match_value
    end

    def number_matches(value, match_value)
      value == match_value
    end

    def boolean_matches(value, match_value)
      value == match_value
    end

    def version_matches(value, match_value)
      value == match_value
    end
  end

  class ContainsMatcher
    include OperatorMatcher

    def string_matches(value, match_value)
      value.include?(match_value)
    end

    def number_matches(_value, _match_value)
      false
    end

    def boolean_matches(_value, _match_value)
      false
    end

    def version_matches(_value, _match_value)
      false
    end
  end

  class StartsWithMatcher
    include OperatorMatcher

    def string_matches(value, match_value)
      value.start_with?(match_value)
    end

    def number_matches(_value, _match_value)
      false
    end

    def boolean_matches(_value, _match_value)
      false
    end

    def version_matches(_value, _match_value)
      false
    end
  end

  class EndsWithMatcher
    include OperatorMatcher

    def string_matches(value, match_value)
      value.end_with?(match_value)
    end

    def number_matches(_value, _match_value)
      false
    end

    def boolean_matches(_value, _match_value)
      false
    end

    def version_matches(_value, _match_value)
      false
    end
  end

  class GreaterThanMatcher
    include OperatorMatcher

    def string_matches(value, match_value)
      value > match_value
    end

    def number_matches(value, match_value)
      value > match_value
    end

    def boolean_matches(_value, _match_value)
      false
    end

    def version_matches(value, match_value)
      value > match_value
    end
  end

  class GreaterThanOrEqualToMatcher
    include OperatorMatcher

    def string_matches(value, match_value)
      value >= match_value
    end

    def number_matches(value, match_value)
      value >= match_value
    end

    def boolean_matches(_value, _match_value)
      false
    end

    def version_matches(value, match_value)
      value >= match_value
    end
  end

  class LessThanMatcher
    include OperatorMatcher

    def string_matches(value, match_value)
      value < match_value
    end

    def number_matches(value, match_value)
      value < match_value
    end

    def boolean_matches(_value, _match_value)
      false
    end

    def version_matches(value, match_value)
      value < match_value
    end
  end

  class LessThanOrEqualToMatcher
    include OperatorMatcher

    def string_matches(value, match_value)
      value <= match_value
    end

    def number_matches(value, match_value)
      value <= match_value
    end

    def boolean_matches(_value, _match_value)
      false
    end

    def version_matches(value, match_value)
      value <= match_value
    end
  end
end

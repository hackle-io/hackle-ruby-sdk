# frozen_string_literal: true

require 'hackle/internal/model/value_type'
require 'hackle/internal/evaluation/match/value/value_matcher'

module Hackle
  class ValueMatcherFactory

    def initialize
      @matchers = {
        ValueType::STRING => StringMatcher.new,
        ValueType::NUMBER => NumberMatcher.new,
        ValueType::BOOLEAN => BooleanMatcher.new,
        ValueType::VERSION => VersionMatcher.new,
        ValueType::JSON => StringMatcher.new
      }.freeze
    end

    # @param value_type [ValueType]
    # @return [ValueMatcher]
    def get(value_type)
      matcher = @matchers[value_type]
      raise ArgumentError, "Unsupported ValueType [#{value_type}]" unless matcher

      matcher
    end
  end
end

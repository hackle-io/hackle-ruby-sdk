# frozen_string_literal: true

require 'rspec'
require 'hackle/internal/model/target'
require 'hackle/internal/model/value_type'
require 'hackle/internal/evaluation/match/value/value_operator_matcher'
require 'hackle/internal/evaluation/match/value/value_matcher_factory'
require 'hackle/internal/evaluation/match/operator/operator_matcher_factory'

module Hackle
  describe ValueOperatorMatcher do
    before do
      @sut = ValueOperatorMatcher.new(
        value_matcher_factory: ValueMatcherFactory.new,
        operator_matcher_factory: OperatorMatcherFactory.new
      )
    end

    it 'true' do
      actual = @sut.matches(
        3,
        TargetMatch.new(
          type: TargetMatchType::MATCH,
          operator: TargetOperator::IN,
          value_type: ValueType::NUMBER,
          values: [1, 2, 3]
        )
      )
      expect(actual).to be(true)
    end

    it 'false' do
      actual = @sut.matches(
        4,
        TargetMatch.new(
          type: TargetMatchType::MATCH,
          operator: TargetOperator::IN,
          value_type: ValueType::NUMBER,
          values: [1, 2, 3]
        )
      )
      expect(actual).to be(false)
    end

    it 'NOT_MATCH false' do
      actual = @sut.matches(
        3,
        TargetMatch.new(
          type: TargetMatchType::NOT_MATCH,
          operator: TargetOperator::IN,
          value_type: ValueType::NUMBER,
          values: [1, 2, 3]
        )
      )
      expect(actual).to be(false)
    end

    it 'NOT_MATCH true' do
      actual = @sut.matches(
        4,
        TargetMatch.new(
          type: TargetMatchType::NOT_MATCH,
          operator: TargetOperator::IN,
          value_type: ValueType::NUMBER,
          values: [1, 2, 3]
        )
      )
      expect(actual).to be(true)
    end

    it 'array true' do
      actual = @sut.matches(
        [5, 4, 3],
        TargetMatch.new(
          type: TargetMatchType::MATCH,
          operator: TargetOperator::IN,
          value_type: ValueType::NUMBER,
          values: [1, 2, 3]
        )
      )
      expect(actual).to be(true)
    end

    it 'array false' do
      actual = @sut.matches(
        [4, 5, 6],
        TargetMatch.new(
          type: TargetMatchType::MATCH,
          operator: TargetOperator::IN,
          value_type: ValueType::NUMBER,
          values: [1, 2, 3]
        )
      )
      expect(actual).to be(false)
    end

    it 'empty array false' do
      actual = @sut.matches(
        [],
        TargetMatch.new(
          type: TargetMatchType::MATCH,
          operator: TargetOperator::IN,
          value_type: ValueType::NUMBER,
          values: [1, 2, 3]
        )
      )
      expect(actual).to be(false)
    end
  end
end

# frozen_string_literal: true

require 'rspec'
require 'hackle/internal/evaluation/match/operator/operator_matcher'
require 'hackle/internal/evaluation/match/operator/operator_matcher_factory'
require 'hackle/internal/model/target'

module Hackle
  RSpec.describe OperatorMatcherFactory do

    it 'get' do
      sut = OperatorMatcherFactory.new

      expect(sut.get(TargetOperator::IN)).to be_a(InMatcher)
      expect(sut.get(TargetOperator::CONTAINS)).to be_a(ContainsMatcher)
      expect(sut.get(TargetOperator::STARTS_WITH)).to be_a(StartsWithMatcher)
      expect(sut.get(TargetOperator::ENDS_WITH)).to be_a(EndsWithMatcher)
      expect(sut.get(TargetOperator::GT)).to be_a(GreaterThanMatcher)
      expect(sut.get(TargetOperator::GTE)).to be_a(GreaterThanOrEqualToMatcher)
      expect(sut.get(TargetOperator::LT)).to be_a(LessThanMatcher)
      expect(sut.get(TargetOperator::LTE)).to be_a(LessThanOrEqualToMatcher)
      expect { sut.get(TargetOperator.new('INVALID')) }.to raise_error(ArgumentError)
    end
  end
end

# frozen_string_literal: true

require 'rspec'
require 'hackle/internal/evaluation/match/value/value_matcher'
require 'hackle/internal/evaluation/match/value/value_matcher_factory'
require 'hackle/internal/model/value_type'

module Hackle
  describe ValueMatcherFactory do
    it 'get' do
      sut = ValueMatcherFactory.new

      expect(sut.get(ValueType::STRING)).to be_a(StringMatcher)
      expect(sut.get(ValueType::NUMBER)).to be_a(NumberMatcher)
      expect(sut.get(ValueType::BOOLEAN)).to be_a(BooleanMatcher)
      expect(sut.get(ValueType::VERSION)).to be_a(VersionMatcher)
      expect(sut.get(ValueType::JSON)).to be_a(StringMatcher)
      expect { sut.get(ValueType.new('INVALID')) }.to raise_error(ArgumentError)
    end
  end
end

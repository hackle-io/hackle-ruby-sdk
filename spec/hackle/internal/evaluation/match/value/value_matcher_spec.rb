# frozen_string_literal: true

require 'rspec'
require 'hackle/internal/evaluation/match/operator/operator_matcher'
require 'hackle/internal/evaluation/match/value/value_matcher'

module Hackle
  class Test
    attr_reader :name, :matcher, :cases

    def initialize(name:, matcher:, cases:)
      @name = name
      @matcher = matcher
      @cases = cases
    end
  end

  RSpec.describe ValueMatcher do
    [
      Test.new(
        name: 'String',
        matcher: StringMatcher.new,
        cases: [
          ['42', '42', true],
          ['42', 42, true],
          [42, '42', true],

          [42.42, '42.42', true],
          ['42.42', 42.42, true],
          [42.42, 42.42, true],

          [true, true, false],
          [true, 1, false],
          ['1', true, false]
        ]
      ),
      Test.new(
        name: 'Number',
        matcher: NumberMatcher.new,
        cases: [
          [42, 42, true],
          [42.42, 42.42, true],
          [0, 0, true],

          ['42', '42', true],
          ['42', 42, true],
          [42, '42', true],

          ['42.42', '42.42', true],
          ['42.42', 42.42, true],
          [42.42, '42.42', true],

          ['42.0', '42.0', true],
          ['42.0', 42.0, true],
          [42.0, '42.0', true],

          ['42a', 42, false],
          [0, 'false', false],
          [0, false, false],
          [true, true, false]
        ]
      ),
      Test.new(
        name: 'Bool',
        matcher: BooleanMatcher.new,
        cases: [
          [true, true, true],
          [false, false, true],
          [false, true, false],
          [true, false, false],
          [1, 1, false],
          [1, true, false],
          [0, false, false],
          [0, 0, false],
          ['true', true, false]
        ]
      ),
      Test.new(
        name: 'Version',
        matcher: VersionMatcher.new,
        cases: [
          ['1', '1', true],
          ['1', '1.0', true],
          ['1.0.0', '2.0.0', false],

          [1, '1', false],
          ['1', 1, false],
          [1, 1, false]
        ]
      )
    ].each do |test|
      it "ValueMatcher #{test.name}" do
        test.cases.each do |tc|
          expect(test.matcher.matches(InMatcher.new, tc[0], tc[1])).to eq(tc[2])
        end
      end
    end
  end
end

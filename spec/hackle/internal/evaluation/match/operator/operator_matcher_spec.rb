# frozen_string_literal: true

require 'rspec'

require 'hackle/internal/evaluation/match/operator/operator_matcher'
require 'hackle/internal/model/version'

module Hackle
  class Test
    attr_reader :name, :matcher, :s, :n, :b, :v

    def initialize(name:, matcher:, s:, n:, b:, v:)
      @name = name
      @matcher = matcher
      @s = s
      @n = n
      @b = b
      @v = v
    end
  end

  RSpec.describe OperatorMatcher do
    def v(value)

      version = Version.parse_or_nil(value)
      raise 'fail' unless version

      version
    end

    [
      Test.new(
        name: 'IN',
        matcher: InMatcher.new,
        s: [
          ['abc', 'abc', true],
          ['abc', 'abc1', false]
        ],
        n: [
          [42, 42, true],
          [42.0, 42, true],
          [42.1, 42.1, true],
          [42, 42.1, false],
          [42, 43, false]
        ],
        b: [
          [true, true, true],
          [false, false, true],
          [true, false, false],
          [false, true, false]
        ],
        v: [
          ['1.0.0', '1.0.0', true],
          ['1.0.0', '2.0.0', false]
        ]
      ),
      Test.new(
        name: 'CONTAINS',
        matcher: ContainsMatcher.new,
        s: [
          ['abc', 'abc', true],
          ['abc', 'a', true],
          ['abc', 'b', true],
          ['abc', 'c', true],
          ['abc', 'ab', true],
          ['abc', 'ac', false],
          ['a', 'ab', false]
        ],
        n: [
          [1, 1, false],
          [1, 11, false],
          [11, 1, false]
        ],
        b: [
          [true, true, false],
          [false, false, false],
          [true, false, false],
          [false, true, false]
        ],
        v: [
          ['1.0.0', '1.0.0', false],
          ['1.0.0', '2.0.0', false]
        ]
      ),
      Test.new(
        name: 'STARTS_WITH',
        matcher: StartsWithMatcher.new,
        s: [
          ['abc', 'abc', true],
          ['abc', 'a', true],
          ['abc', 'ab', true],
          ['abc', 'b', false]
        ],
        n: [
          [1, 1, false],
          [1, 11, false],
          [11, 1, false]
        ],
        b: [
          [true, true, false],
          [false, false, false],
          [true, false, false],
          [false, true, false]
        ],
        v: [
          ['1.0.0', '1.0.0', false],
          ['1.0.0', '2.0.0', false]
        ]
      ),
      Test.new(
        name: 'ENDS_WITH',
        matcher: EndsWithMatcher.new,
        s: [
          ['abc', 'abc', true],
          ['abc', 'a', false],
          ['abc', 'ab', false],
          ['abc', 'b', false],
          ['abc', 'c', true],
          ['abc', 'bc', true]
        ],
        n: [
          [1, 1, false],
          [1, 11, false],
          [11, 1, false]
        ],
        b: [
          [true, true, false],
          [false, false, false],
          [true, false, false],
          [false, true, false]
        ],
        v: [
          ['1.0.0', '1.0.0', false],
          ['1.0.0', '2.0.0', false]
        ]
      ),
      Test.new(
        name: 'GT',
        matcher: GreaterThanMatcher.new,
        s: [
          ['41', '42', false],
          ['42', '42', false],
          ['43', '42', true],

          ['20230114', '20230115', false],
          ['20230115', '20230115', false],
          ['20230116', '20230115', true],

          ['2023-01-14', '2023-01-15', false],
          ['2023-01-15', '2023-01-15', false],
          ['2023-01-16', '2023-01-15', true],

          ['a', 'a', false],
          ['a', 'A', true],
          ['A', 'a', false],
          ['aa', 'a', true],
          ['a', 'aa', false]
        ],
        n: [
          [1, 2, false],
          [2, 2, false],
          [3, 2, true],

          [0.999, 1, false],
          [1, 1, false],
          [1.001, 1, true]
        ],
        b: [
          [true, true, false],
          [false, false, false],
          [true, false, false],
          [false, true, false]
        ],
        v: [
          ['1.0.0', '2.0.0', false],
          ['2.0.0', '2.0.0', false],
          ['3.0.0', '2.0.0', true]
        ]
      ),
      Test.new(
        name: 'GTE',
        matcher: GreaterThanOrEqualToMatcher.new,
        s: [
          ['41', '42', false],
          ['42', '42', true],
          ['43', '42', true],

          ['20230114', '20230115', false],
          ['20230115', '20230115', true],
          ['20230116', '20230115', true],

          ['2023-01-14', '2023-01-15', false],
          ['2023-01-15', '2023-01-15', true],
          ['2023-01-16', '2023-01-15', true],

          ['a', 'a', true],
          ['a', 'A', true],
          ['A', 'a', false],
          ['aa', 'a', true],
          ['a', 'aa', false]
        ],
        n: [
          [1, 2, false],
          [2, 2, true],
          [3, 2, true],

          [0.999, 1, false],
          [1, 1, true],
          [1.001, 1, true]
        ],
        b: [
          [true, true, false],
          [false, false, false],
          [true, false, false],
          [false, true, false]
        ],
        v: [
          ['1.0.0', '2.0.0', false],
          ['2.0.0', '2.0.0', true],
          ['3.0.0', '2.0.0', true]
        ]
      ),
      Test.new(
        name: 'LT',
        matcher: LessThanMatcher.new,
        s: [
          ['41', '42', true],
          ['42', '42', false],
          ['43', '42', false],

          ['20230114', '20230115', true],
          ['20230115', '20230115', false],
          ['20230116', '20230115', false],

          ['2023-01-14', '2023-01-15', true],
          ['2023-01-15', '2023-01-15', false],
          ['2023-01-16', '2023-01-15', false],

          ['a', 'a', false],
          ['a', 'A', false],
          ['A', 'a', true],
          ['aa', 'a', false],
          ['a', 'aa', true]
        ],
        n: [
          [1, 2, true],
          [2, 2, false],
          [3, 2, false],

          [0.999, 1, true],
          [1, 1, false],
          [1.001, 1, false]
        ],
        b: [
          [true, true, false],
          [false, false, false],
          [true, false, false],
          [false, true, false]
        ],
        v: [
          ['1.0.0', '2.0.0', true],
          ['2.0.0', '2.0.0', false],
          ['3.0.0', '2.0.0', false]
        ]
      ),
      Test.new(
        name: 'LTE',
        matcher: LessThanOrEqualToMatcher.new,
        s: [
          ['41', '42', true],
          ['42', '42', true],
          ['43', '42', false],

          ['20230114', '20230115', true],
          ['20230115', '20230115', true],
          ['20230116', '20230115', false],

          ['2023-01-14', '2023-01-15', true],
          ['2023-01-15', '2023-01-15', true],
          ['2023-01-16', '2023-01-15', false],

          ['a', 'a', true],
          ['a', 'A', false],
          ['A', 'a', true],
          ['aa', 'a', false],
          ['a', 'aa', true]
        ],
        n: [
          [1, 2, true],
          [2, 2, true],
          [3, 2, false],

          [0.999, 1, true],
          [1, 1, true],
          [1.001, 1, false]
        ],
        b: [
          [true, true, false],
          [false, false, false],
          [true, false, false],
          [false, true, false]
        ],
        v: [
          ['1.0.0', '2.0.0', true],
          ['2.0.0', '2.0.0', true],
          ['3.0.0', '2.0.0', false]
        ]
      )
    ].each do |test|
      test.s.each do |tc|
        it "#{test.name} string" do
          expect(test.matcher.string_matches(tc[0], tc[1])).to eq(tc[2])
        end
      end

      test.n.each do |tc|
        it "#{test.name} number" do
          expect(test.matcher.number_matches(tc[0], tc[1])).to eq(tc[2])
        end
      end

      test.b.each do |tc|
        it "#{test.name} boolean" do
          expect(test.matcher.boolean_matches(tc[0], tc[1])).to eq(tc[2])
        end
      end

      test.v.each do |tc|
        it "#{test.name} version" do
          expect(test.matcher.version_matches(v(tc[0]), v(tc[1]))).to eq(tc[2])
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'rspec'
require 'hackle/internal/evaluation/match/condition/user/user_condition_matcher'
require 'hackle/internal/evaluation/evaluator/evaluator'
require 'hackle/internal/model/target'
require 'hackle/internal/user/hackle_user'

module Hackle
  RSpec.describe UserConditionMatcher do
    before do
      @user_value_resolver = double
      @value_operator_matcher = double
      @sut = UserConditionMatcher.new(
        user_value_resolver: @user_value_resolver,
        value_operator_matcher: @value_operator_matcher
      )
    end

    it 'when error on resolve value then raise error' do
      allow(@user_value_resolver).to receive(:resolve_or_nil).and_raise('Fail')

      request = Evaluators.request
      context = Evaluator.context
      condition = TargetCondition.new(key: double, match: double)

      expect { @sut.matches(request, context, condition) }.to raise_error('Fail')
    end

    it 'when user value is nil then false' do
      allow(@user_value_resolver).to receive(:resolve_or_nil).and_return(nil)

      request = Evaluators.request
      context = Evaluator.context
      condition = TargetCondition.new(key: double, match: double)

      actual = @sut.matches(request, context, condition)
      expect(actual).to eq(false)
    end

    it 'when user value is exist then matches user value' do
      allow(@user_value_resolver).to receive(:resolve_or_nil).and_return('42')
      allow(@value_operator_matcher).to receive(:matches).and_return(true)

      request = Evaluators.request
      context = Evaluator.context
      condition = TargetCondition.new(key: double, match: double)

      actual = @sut.matches(request, context, condition)
      expect(actual).to eq(true)
    end
  end

  RSpec.describe UserValueResolver do

    before do
      @sut = UserValueResolver.new
    end

    it 'user id present' do
      user = HackleUser.builder.identifier('my_id', '42').build
      key = TargetKey.new(type: TargetKeyType::USER_ID, name: 'my_id')

      actual = @sut.resolve_or_nil(user, key)

      expect(actual).to eq('42')
    end

    it 'user id absent' do
      user = HackleUser.builder.identifier('my_id', '42').build
      key = TargetKey.new(type: TargetKeyType::USER_ID, name: 'your_id')

      actual = @sut.resolve_or_nil(user, key)

      expect(actual).to eq(nil)
    end

    it 'user property present' do
      user = HackleUser.builder.property('age', 42).build
      key = TargetKey.new(type: TargetKeyType::USER_PROPERTY, name: 'age')

      actual = @sut.resolve_or_nil(user, key)

      expect(actual).to eq(42)
    end

    it 'user property absent' do
      user = HackleUser.builder.property('age', 42).build
      key = TargetKey.new(type: TargetKeyType::USER_PROPERTY, name: 'grade')

      actual = @sut.resolve_or_nil(user, key)

      expect(actual).to eq(nil)
    end

    it 'hackle property' do
      user = HackleUser.builder.property('age', 42).build
      key = TargetKey.new(type: TargetKeyType::HACKLE_PROPERTY, name: 'platform')

      actual = @sut.resolve_or_nil(user, key)

      expect(actual).to eq(nil)
    end

    it 'unsupported type' do
      user = HackleUser.builder.property('age', 42).build
      key = TargetKey.new(type: TargetKeyType::AB_TEST, name: 'platform')

      expect { @sut.resolve_or_nil(user, key) }.to raise_error(ArgumentError)
    end
  end
end

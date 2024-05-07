# frozen_string_literal: true

require 'hackle/internal/model/target'
require 'hackle/internal/evaluation/match/condition/condition_matcher'

module Hackle
  class UserConditionMatcher
    include ConditionMatcher

    # @param user_value_resolver [UserValueResolver]
    # @param value_operator_matcher [ValueOperatorMatcher]
    def initialize(user_value_resolver:, value_operator_matcher:)
      # @type [UserValueResolver]
      @user_value_resolver = user_value_resolver
      # @type [ValueOperatorMatcher]
      @value_operator_matcher = value_operator_matcher
    end

    def matches(request, context, condition)
      user_value = @user_value_resolver.resolve_or_nil(request.user, condition.key)
      return false if user_value.nil?

      @value_operator_matcher.matches(user_value, condition.match)
    end
  end

  class UserValueResolver
    # @param user [HackleUser]
    # @param key [TargetKey]
    # @return [Object, nil]
    def resolve_or_nil(user, key)
      case key.type
      when TargetKeyType::USER_ID
        user.identifiers[key.name]
      when TargetKeyType::USER_PROPERTY
        user.properties[key.name]
      when TargetKeyType::HACKLE_PROPERTY
        nil
      else
        raise ArgumentError, "unsupported TargetKeyType: #{key.type}"
      end
    end
  end
end

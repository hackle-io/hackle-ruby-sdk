# frozen_string_literal: true

module Hackle
  class TargetMatcher

    # @param condition_matcher_factory [ConditionMatcherFactory]
    def initialize(condition_matcher_factory:)
      # @type [ConditionMatcherFactory]
      @condition_matcher_factory = condition_matcher_factory
    end

    # @param request [EvaluatorRequest]
    # @param context [EvaluatorContext]
    # @param target [Target]
    # @return [boolean]
    def matches(request, context, target)
      target.conditions.all? { |it| condition_matches(request, context, it) }
    end

    private

    # @param request [EvaluatorRequest]
    # @param context [EvaluatorContext]
    # @param condition [TargetCondition]
    # @return [boolean]
    def condition_matches(request, context, condition)
      condition_matcher = @condition_matcher_factory.get(condition.key.type)
      condition_matcher.matches(request, context, condition)
    end
  end
end

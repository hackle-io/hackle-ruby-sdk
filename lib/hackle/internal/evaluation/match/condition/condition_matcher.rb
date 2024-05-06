# frozen_string_literal: true

module Hackle
  module ConditionMatcher
    # @param request [EvaluatorRequest]
    # @param context [EvaluatorContext]
    # @param condition [TargetCondition]
    # @return [boolean]
    def matches(request, context, condition) end
  end
end

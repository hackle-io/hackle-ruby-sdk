# frozen_string_literal: true

module Hackle
  module FlowEvaluator
    # @param request [EvaluatorRequest]
    # @param context [EvaluatorContext]
    # @param next_flow [EvaluationFlow]
    # @return [EvaluatorEvaluation, nil]
    def evaluate(request, context, next_flow) end
  end
end

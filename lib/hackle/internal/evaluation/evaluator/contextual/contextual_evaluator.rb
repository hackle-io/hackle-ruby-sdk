# frozen_string_literal: true

require 'hackle/internal/evaluation/evaluator/evaluator'

module Hackle
  module ContextualEvaluator
    include Evaluator

    # @param request [EvaluatorRequest]
    # @return [boolean]
    def supports?(request) end

    # @param request [EvaluatorRequest]
    # @param context [EvaluatorContext]
    # @return [EvaluatorEvaluation]
    def evaluate_internal(request, context) end

    def evaluate(request, context)
      raise ArgumentError, 'circular evaluation has occurred' if context.request_include?(request)

      context.add_request(request)
      begin
        evaluate_internal(request, context)
      ensure
        context.remove_request(request)
      end
    end
  end
end

# frozen_string_literal: true

require 'hackle/internal/evaluation/evaluator/evaluator'

module Hackle
  class DelegatingEvaluator
    include Evaluator

    def initialize
      # @type [Array<ContextualEvaluator>]
      @evaluators = []
    end

    # @param evaluator [ContextualEvaluator]
    def add(evaluator)
      @evaluators << evaluator
    end

    def evaluate(request, context)
      evaluator = @evaluators.find { |it| it.supports?(request) }
      raise ArgumentError, "unsupported EvaluatorRequest [#{request.class}]" if evaluator.nil?

      evaluator.evaluate(request, context)
    end
  end
end

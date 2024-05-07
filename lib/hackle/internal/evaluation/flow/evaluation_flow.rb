# frozen_string_literal: true

module Hackle
  module EvaluationFlow
    # @param request [EvaluatorRequest]
    # @param context [EvaluatorContext]
    # @return [EvaluatorEvaluation, nil]
    def evaluate(request, context) end

    # @param evaluators [Array<FlowEvaluator>]
    # @return [Hackle::EvaluationFlow]
    def self.create(evaluators)
      flow = End.new
      evaluators.reverse_each do |evaluator|
        flow = Decision.new(evaluator, flow)
      end
      flow
    end

    class End
      include EvaluationFlow

      def evaluate(request, context)
        nil
      end
    end

    class Decision
      include EvaluationFlow

      # @return [FlowEvaluator]
      attr_reader :evaluator

      # @return [EvaluationFlow]
      attr_reader :next_flow

      # @param evaluator [FlowEvaluator]
      # @param next_flow [EvaluationFlow]
      def initialize(evaluator, next_flow)
        @evaluator = evaluator
        @next_flow = next_flow
      end

      def evaluate(request, context)
        evaluator.evaluate(request, context, next_flow)
      end
    end
  end
end

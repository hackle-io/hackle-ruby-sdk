# frozen_string_literal: true

require 'rspec'
require 'hackle/internal/evaluation/flow/evaluation_flow'
require 'hackle/internal/evaluation/flow/flow_evaluator'
require 'hackle/internal/evaluation/evaluator/evaluator'

module Hackle
  RSpec.describe EvaluationFlow do
    it 'flow' do
      flow = EvaluationFlow::End.new
      expect(flow.evaluate(double('request'), Evaluator.context)).to be_nil

      evaluation = EvaluatorEvaluation.new(reason: '1', target_evaluations: [])
      flow = EvaluationFlow::Decision.new(MockEvaluator.new(evaluation), flow)
      expect(flow.evaluate(double('request'), Evaluator.context)).to eq(evaluation)
    end

    it 'create' do
      e1 = MockEvaluator.new(double('1'))
      e2 = MockEvaluator.new(double('2'))
      e3 = MockEvaluator.new(double('3'))

      def decision_with(flow, evaluator)
        expect(flow).to be_a(EvaluationFlow::Decision)
        expect(flow.evaluator).to eq(evaluator)
        flow.next_flow
      end

      flow = EvaluationFlow.create([e1, e2, e3])

      flow = decision_with(flow, e1)
      flow = decision_with(flow, e2)
      flow = decision_with(flow, e3)

      expect(flow).to be_a(EvaluationFlow::End)
    end
  end

  class MockEvaluator
    include FlowEvaluator

    def initialize(evaluation)
      @evaluation = evaluation
    end

    def evaluate(_request, _context, _next_flow)
      @evaluation
    end
  end
end

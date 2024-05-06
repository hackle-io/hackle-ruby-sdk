# frozen_string_literal: true

require 'rspec'
require 'hackle/internal/evaluation/evaluator/contextual/contextual_evaluator'
require 'hackle/internal/evaluation/evaluator/evaluator'

module Hackle
  RSpec.describe ContextualEvaluator do
    it 'when context contains request then raise error - circular evaluation' do
      context = Evaluator.context
      request = Evaluators.request
      context.add_request(request)

      sut = MockContextualEvaluator.new(request, double('evaluation'))

      expect { sut.evaluate(request, context) }.to raise_error(ArgumentError, 'circular evaluation has occurred')
    end

    it 'evaluate' do
      context = Evaluator.context
      request = Evaluators.request
      evaluation = Evaluators.evaluation
      sut = MockContextualEvaluator.new(request, evaluation)

      actual = sut.evaluate(request, context)

      expect(actual).to eq(evaluation)
    end
  end

  class MockContextualEvaluator
    include ContextualEvaluator

    def initialize(request, evaluation)
      @request = request
      @evaluation = evaluation
    end

    def supports?(request)
      @request == request
    end

    def evaluate_internal(request, context)
      @evaluation
    end
  end
end

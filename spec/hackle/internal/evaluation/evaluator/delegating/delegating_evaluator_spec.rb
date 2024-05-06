# frozen_string_literal: true

require 'rspec'
require 'hackle/internal/evaluation/evaluator/delegating/delegating_evaluator'
require 'hackle/internal/evaluation/evaluator/contextual/contextual_evaluator'
require 'hackle/internal/evaluation/evaluator/evaluator'
require 'hackle/internal/workspace/workspace'

module Hackle
  describe DelegatingEvaluator do

    it 'evaluator' do
      sut = DelegatingEvaluator.new
      expect { sut.evaluate(double('Request'), Evaluator.context) }.to raise_error(ArgumentError)

      r1 = Evaluators.request(type: 'EXPERIMENT', id: 1)
      e1 = Evaluators.evaluation
      evaluator1 = MockContextualEvaluator.new(r1, e1)
      sut.add(evaluator1)
      expect(sut.evaluate(r1, Evaluator.context)).to be(e1)

      r2 = Evaluators.request(type: 'EXPERIMENT', id: 2)
      expect { sut.evaluate(r2, Evaluator.context) }.to raise_error(ArgumentError)
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

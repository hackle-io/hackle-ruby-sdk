# frozen_string_literal: true

require 'rspec'
require 'hackle/internal/evaluation/evaluator/evaluator'

module Hackle
  describe EvaluatorContext do
    it 'request' do
      context = Evaluator.context
      expect(context.requests.length).to eq(0)

      request1 = Evaluators.request(id: 1)
      expect(context.request_include?(request1)).to eq(false)

      context.add_request(request1)
      expect(context.request_include?(request1)).to eq(true)

      requests1 = context.requests
      expect(requests1.length).to eq(1)

      request2 = Evaluators.request(id: 2)
      expect(context.request_include?(request2)).to eq(false)

      context.add_request(request2)
      expect(context.request_include?(request2)).to eq(true)

      requests2 = context.requests
      expect(requests2.length).to eq(2)

      context.remove_request(request2)
      expect(context.requests.length).to eq(1)

      context.remove_request(request1)
      expect(context.requests.length).to eq(0)

      expect(requests1.length).to eq(1)
      expect(requests2.length).to eq(2)
      expect(context.request_include?(request1)).to eq(false)
      expect(context.request_include?(request2)).to eq(false)
    end

    it 'evaluation' do
      context = Evaluator.context
      expect(context.evaluations.length).to eq(0)

      context.add_evaluation(Evaluators.evaluation(reason: '1'))
      expect(context.evaluations.length).to eq(1)

      context.add_evaluation(Evaluators.evaluation(reason: '2'))
      expect(context.evaluations.length).to eq(2)
    end
  end
end

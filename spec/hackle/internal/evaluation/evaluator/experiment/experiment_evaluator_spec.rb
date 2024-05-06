# frozen_string_literal: true

require 'rspec'
require 'models'
require 'hackle/internal/evaluation/evaluator/experiment/experiment_evaluator'

module Hackle
  describe ExperimentEvaluator do

    before do
      @flow_factory = double
      @sut = ExperimentEvaluator.new(flow_factory: @flow_factory)
    end

    it 'supports' do
      expect(@sut.supports?(Experiments.request)).to eq(true)

      request = Evaluators.request(type: 'EXPERIMENT')
      expect(@sut.supports?(request)).to eq(false)
    end

    it 'evaluate' do
      request = Experiments.request
      context = Evaluator.context

      evaluation_flow = double
      evaluation = double
      allow(evaluation_flow).to receive(:evaluate).and_return(evaluation)

      allow(@flow_factory).to receive(:get).and_return(evaluation_flow)

      actual = @sut.evaluate(request, context)

      expect(actual).to be(evaluation)
    end

    it 'not evaluated' do
      request = Experiments.request
      context = Evaluator.context

      evaluation_flow = double
      allow(evaluation_flow).to receive(:evaluate).and_return(nil)

      allow(@flow_factory).to receive(:get).and_return(evaluation_flow)

      actual = @sut.evaluate(request, context)

      expect(actual.variation_key).to be('A')
      expect(actual.reason).to be('TRAFFIC_NOT_ALLOCATED')
    end
  end
end


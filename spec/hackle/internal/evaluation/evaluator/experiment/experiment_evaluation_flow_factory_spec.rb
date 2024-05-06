# frozen_string_literal: true

require 'rspec'
require 'models'
require 'hackle/internal/evaluation/flow/evaluation_flow'
require 'hackle/internal/evaluation/evaluator/experiment/experiment_evaluation_flow_factory'

module Hackle
  RSpec.describe ExperimentEvaluationFlowFactory do

    def decision_with(flow, clazz)
      expect(flow).to be_a(EvaluationFlow::Decision)
      expect(flow.evaluator).to be_a(clazz)
      flow.next_flow
    end

    it 'AB_TEST' do
      factory = ExperimentEvaluationFlowFactory.new(target_matcher: double, bucketer: double)
      flow = factory.get(ExperimentType::AB_TEST)

      flow = decision_with(flow, OverrideExperimentFlowEvaluator)
      flow = decision_with(flow, IdentifierExperimentFlowEvaluator)
      flow = decision_with(flow, ContainerExperimentFlowEvaluator)
      flow = decision_with(flow, TargetExperimentFlowEvaluator)
      flow = decision_with(flow, DraftExperimentFlowEvaluator)
      flow = decision_with(flow, PausedExperimentFlowEvaluator)
      flow = decision_with(flow, CompletedExperimentFlowEvaluator)
      flow = decision_with(flow, TrafficAllocateExperimentFlowEvaluator)
      expect(flow).to be_a(EvaluationFlow::End)
    end

    it 'FEATURE_FLAG' do
      factory = ExperimentEvaluationFlowFactory.new(target_matcher: double, bucketer: double)
      flow = factory.get(ExperimentType::FEATURE_FLAG)

      flow = decision_with(flow, DraftExperimentFlowEvaluator)
      flow = decision_with(flow, PausedExperimentFlowEvaluator)
      flow = decision_with(flow, CompletedExperimentFlowEvaluator)
      flow = decision_with(flow, OverrideExperimentFlowEvaluator)
      flow = decision_with(flow, IdentifierExperimentFlowEvaluator)
      flow = decision_with(flow, TargetRuleExperimentFlowEvaluator)
      flow = decision_with(flow, DefaultRuleExperimentFlowEvaluator)
      expect(flow).to be_a(EvaluationFlow::End)
    end

    it 'unsupported type' do
      factory = ExperimentEvaluationFlowFactory.new(target_matcher: double, bucketer: double)

      expect { factory.get(ExperimentType.new('INVALID')) }.to raise_error(ArgumentError, 'unsupported ExperimentType [INVALID]')
    end
  end
end


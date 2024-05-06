# frozen_string_literal: true

require 'hackle/internal/model/experiment'
require 'hackle/internal/evaluation/flow/evaluation_flow'
require 'hackle/internal/evaluation/evaluator/experiment/experiment_resolver'
require 'hackle/internal/evaluation/evaluator/experiment/experiment_flow_evaluator'

module Hackle
  class ExperimentEvaluationFlowFactory
    # @param target_matcher [TargetMatcher]
    # @param bucketer [Bucketer]
    def initialize(target_matcher:, bucketer:)

      action_resolver = ExperimentActionResolver.new(bucketer: bucketer)
      override_resolver = ExperimentOverrideResolver.new(
        target_matcher: target_matcher,
        action_resolver: action_resolver
      )
      container_resolver = ExperimentContainerResolver.new(bucketer: bucketer)
      target_determiner = ExperimentTargetDeterminer.new(target_matcher: target_matcher)
      target_rule_determiner = ExperimentTargetRuleDeterminer.new(target_matcher: target_matcher)

      # @type [ExperimentFlow]
      @ab_test_flow = EvaluationFlow.create(
        [
          OverrideExperimentFlowEvaluator.new(override_resolver: override_resolver),
          IdentifierExperimentFlowEvaluator.new,
          ContainerExperimentFlowEvaluator.new(container_resolver: container_resolver),
          TargetExperimentFlowEvaluator.new(target_determiner: target_determiner),
          DraftExperimentFlowEvaluator.new,
          PausedExperimentFlowEvaluator.new,
          CompletedExperimentFlowEvaluator.new,
          TrafficAllocateExperimentFlowEvaluator.new(action_resolver: action_resolver)
        ]
      )

      # @type [ExperimentFlow]
      @feature_flag_flow = EvaluationFlow.create(
        [
          DraftExperimentFlowEvaluator.new,
          PausedExperimentFlowEvaluator.new,
          CompletedExperimentFlowEvaluator.new,
          OverrideExperimentFlowEvaluator.new(override_resolver: override_resolver),
          IdentifierExperimentFlowEvaluator.new,
          TargetRuleExperimentFlowEvaluator.new(
            target_rule_determiner: target_rule_determiner,
            action_resolver: action_resolver
          ),
          DefaultRuleExperimentFlowEvaluator.new(action_resolver: action_resolver)
        ]
      )
    end

    # @param experiment_type [ExperimentType]
    # @return [ExperimentFlow]
    def get(experiment_type)
      case experiment_type
      when ExperimentType::AB_TEST
        @ab_test_flow
      when ExperimentType::FEATURE_FLAG
        @feature_flag_flow
      else
        raise ArgumentError, "unsupported ExperimentType [#{experiment_type}]"
      end
    end
  end
end

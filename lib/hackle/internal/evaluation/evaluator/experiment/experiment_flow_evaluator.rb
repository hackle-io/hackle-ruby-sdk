# frozen_string_literal: true

require 'hackle/internal/evaluation/evaluator/experiment/experiment_evaluator'
require 'hackle/internal/evaluation/flow/evaluation_flow'
require 'hackle/internal/evaluation/flow/flow_evaluator'
require 'hackle/internal/model/experiment'
require 'hackle/internal/model/decision_reason'

module Hackle
  module ExperimentFlow
    include EvaluationFlow

    # @param request [ExperimentRequest]
    # @param context [EvaluatorContext]
    # @return [ExperimentEvaluation, nil]
    def evaluate(request, context) end
  end

  module ExperimentFlowEvaluator
    include FlowEvaluator

    # @param request [ExperimentRequest]
    # @param context [EvaluatorContext]
    # @param next_flow [ExperimentFlow]
    # @return [ExperimentEvaluation, nil]
    def evaluate(request, context, next_flow) end
  end

  class OverrideExperimentFlowEvaluator
    include ExperimentFlowEvaluator

    # @param override_resolver [ExperimentOverrideResolver]
    def initialize(override_resolver:)
      # @type [ExperimentOverrideResolver]
      @override_resolver = override_resolver
    end

    def evaluate(request, context, next_flow)
      overridden_variation = @override_resolver.resolve_or_nil(request, context)
      return next_flow.evaluate(request, context) if overridden_variation.nil?

      case request.experiment.type
      when ExperimentType::AB_TEST
        ExperimentEvaluation.create(request, context, overridden_variation, DecisionReason::OVERRIDDEN)
      when ExperimentType::FEATURE_FLAG
        ExperimentEvaluation.create(request, context, overridden_variation, DecisionReason::INDIVIDUAL_TARGET_MATCH)
      else
        raise ArgumentError, "unsupported experiment type [#{request.experiment.type}]"
      end
    end
  end

  class DraftExperimentFlowEvaluator
    include ExperimentFlowEvaluator

    def evaluate(request, context, next_flow)
      return next_flow.evaluate(request, context) if request.experiment.status != ExperimentStatus::DRAFT

      ExperimentEvaluation.create_default(request, context, DecisionReason::EXPERIMENT_DRAFT)
    end
  end

  class PausedExperimentFlowEvaluator
    include ExperimentFlowEvaluator

    def evaluate(request, context, next_flow)
      return next_flow.evaluate(request, context) if request.experiment.status != ExperimentStatus::PAUSED

      case request.experiment.type
      when ExperimentType::AB_TEST
        ExperimentEvaluation.create_default(request, context, DecisionReason::EXPERIMENT_PAUSED)
      when ExperimentType::FEATURE_FLAG
        ExperimentEvaluation.create_default(request, context, DecisionReason::FEATURE_FLAG_INACTIVE)
      else
        raise ArgumentError, "unsupported experiment type [#{request.experiment.type}]"
      end
    end
  end

  class CompletedExperimentFlowEvaluator
    include ExperimentFlowEvaluator

    def evaluate(request, context, next_flow)
      return next_flow.evaluate(request, context) if request.experiment.status != ExperimentStatus::COMPLETED

      winner_variation = request.experiment.winner_variation_or_nil
      raise ArgumentError, "winner variation [#{request.experiment.id}]" if winner_variation.nil?

      ExperimentEvaluation.create(request, context, winner_variation, DecisionReason::EXPERIMENT_COMPLETED)
    end
  end

  class TargetExperimentFlowEvaluator
    include ExperimentFlowEvaluator

    # @param target_determiner [ExperimentTargetDeterminer]
    def initialize(target_determiner:)
      # @type [ExperimentTargetDeterminer]
      @target_determiner = target_determiner
    end

    def evaluate(request, context, next_flow)
      if request.experiment.type != ExperimentType::AB_TEST
        raise ArgumentError, "experiment type must be AB_TEST [#{request.experiment.id}]"
      end

      is_user_in_experiment_target = @target_determiner.user_in_experiment_target?(request, context)
      if is_user_in_experiment_target
        next_flow.evaluate(request, context)
      else
        ExperimentEvaluation.create_default(request, context, DecisionReason::NOT_IN_EXPERIMENT_TARGET)
      end
    end
  end

  class TrafficAllocateExperimentFlowEvaluator
    include ExperimentFlowEvaluator

    # @param action_resolver [ExperimentActionResolver]
    def initialize(action_resolver:)
      # @type [ExperimentActionResolver]
      @action_resolver = action_resolver
    end

    def evaluate(request, context, _next_flow)
      if request.experiment.status != ExperimentStatus::RUNNING
        raise ArgumentError, "experiment status must be RUNNING [#{request.experiment.id}]"
      end
      if request.experiment.type != ExperimentType::AB_TEST
        raise ArgumentError, "experiment type must be AB_TEST [#{request.experiment.id}]"
      end

      variation = @action_resolver.resolve_or_nil(request, request.experiment.default_rule)
      if variation.nil?
        return ExperimentEvaluation.create_default(request, context, DecisionReason::TRAFFIC_NOT_ALLOCATED)
      end
      if variation.is_dropped
        return ExperimentEvaluation.create_default(request, context, DecisionReason::VARIATION_DROPPED)
      end

      ExperimentEvaluation.create(request, context, variation, DecisionReason::TRAFFIC_ALLOCATED)
    end
  end

  class TargetRuleExperimentFlowEvaluator
    include ExperimentFlowEvaluator

    # @param target_rule_determiner [ExperimentTargetRuleDeterminer]
    # @param action_resolver [ExperimentActionResolver]
    def initialize(target_rule_determiner:, action_resolver:)
      # @type [ExperimentTargetRuleDeterminer]
      @target_rule_determiner = target_rule_determiner
      # @type [ExperimentActionResolver]
      @action_resolver = action_resolver
    end

    def evaluate(request, context, next_flow)
      if request.experiment.status != ExperimentStatus::RUNNING
        raise ArgumentError, "experiment status must be RUNNING [#{request.experiment.id}]"
      end
      if request.experiment.type != ExperimentType::FEATURE_FLAG
        raise ArgumentError, "experiment type must be FEATURE_FLAG [#{request.experiment.id}]"
      end

      return next_flow.evaluate(request, context) if request.user.identifiers[request.experiment.identifier_type].nil?

      target_rule = @target_rule_determiner.determine_target_rule_or_nil(request, context)
      return next_flow.evaluate(request, context) if target_rule.nil?

      variation = @action_resolver.resolve_or_nil(request, target_rule.action)
      raise ArgumentError, "feature flag must decide the variation [#{request.experiment.id}]" if variation.nil?

      ExperimentEvaluation.create(request, context, variation, DecisionReason::TARGET_RULE_MATCH)
    end
  end

  class DefaultRuleExperimentFlowEvaluator
    include ExperimentFlowEvaluator

    # @param action_resolver [ExperimentActionResolver]
    def initialize(action_resolver:)
      # @type [ExperimentActionResolver]
      @action_resolver = action_resolver
    end

    def evaluate(request, context, _next_flow)
      if request.experiment.status != ExperimentStatus::RUNNING
        raise ArgumentError, "experiment status must be RUNNING [#{request.experiment.id}]"
      end
      if request.experiment.type != ExperimentType::FEATURE_FLAG
        raise ArgumentError, "experiment type must be FEATURE_FLAG [#{request.experiment.id}]"
      end

      if request.user.identifiers[request.experiment.identifier_type].nil?
        return ExperimentEvaluation.create_default(request, context, DecisionReason::DEFAULT_RULE)
      end

      variation = @action_resolver.resolve_or_nil(request, request.experiment.default_rule)
      raise ArgumentError, "feature flag must decide the variation [#{request.experiment.id}]" if variation.nil?

      ExperimentEvaluation.create(request, context, variation, DecisionReason::DEFAULT_RULE)
    end
  end

  class ContainerExperimentFlowEvaluator
    include ExperimentFlowEvaluator

    # @param container_resolver [ExperimentContainerResolver]
    def initialize(container_resolver:)
      # @type [ExperimentContainerResolver]
      @container_resolver = container_resolver
    end

    def evaluate(request, context, next_flow)
      container_id = request.experiment.container_id
      return next_flow.evaluate(request, context) if container_id.nil?

      container = request.workspace.get_container_or_nil(container_id)
      raise ArgumentError, "container [#{container_id}]" if container.nil?

      is_user_in_container_group = @container_resolver.user_in_container_group?(request, container)
      if is_user_in_container_group
        next_flow.evaluate(request, context)
      else
        ExperimentEvaluation.create_default(request, context, DecisionReason::NOT_IN_MUTUAL_EXCLUSION_EXPERIMENT)
      end
    end
  end

  class IdentifierExperimentFlowEvaluator
    include ExperimentFlowEvaluator

    def evaluate(request, context, next_flow)
      if request.user.identifiers[request.experiment.identifier_type].nil?
        ExperimentEvaluation.create_default(request, context, DecisionReason::IDENTIFIER_NOT_FOUND)
      else
        next_flow.evaluate(request, context)
      end
    end
  end
end

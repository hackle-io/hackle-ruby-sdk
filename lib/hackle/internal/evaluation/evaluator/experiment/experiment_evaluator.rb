# frozen_string_literal: true

require 'hackle/internal/model/decision_reason'
require 'hackle/internal/evaluation/evaluator/evaluator'
require 'hackle/internal/evaluation/evaluator/contextual/contextual_evaluator'

module Hackle
  class ExperimentEvaluator
    include ContextualEvaluator

    # @param flow_factory [ExperimentEvaluationFlowFactory]
    def initialize(flow_factory:)
      # @type [ExperimentEvaluationFlowFactory]
      @flow_factory = flow_factory
    end

    def supports?(request)
      request.is_a?(ExperimentRequest)
    end

    # @param request [ExperimentRequest]
    # @param context [EvaluatorContext]
    # @return [ExperimentEvaluation]
    def evaluate_internal(request, context)
      evaluation_flow = @flow_factory.get(request.experiment.type)
      evaluation = evaluation_flow.evaluate(request, context)
      return evaluation unless evaluation.nil?

      ExperimentEvaluation.create_default(request, context, DecisionReason::TRAFFIC_NOT_ALLOCATED)
    end
  end

  class ExperimentRequest < EvaluatorRequest
    # @return [Experiment]
    attr_reader :experiment

    # @return [String]
    attr_reader :default_variation_key

    # @param key [EvaluatorKey]
    # @param workspace [Workspace]
    # @param user [HackleUser]
    # @param experiment [Experiment]
    # @param default_variation_key [String]
    def initialize(key:, workspace:, user:, experiment:, default_variation_key:)
      super(key: key, workspace: workspace, user: user)
      @experiment = experiment
      @default_variation_key = default_variation_key
    end

    # @param workspace [Workspace]
    # @param user [HackleUser]
    # @param experiment [Experiment]
    # @param default_variation_key [String]
    # @return [Hackle::ExperimentRequest]
    def self.create(workspace, user, experiment, default_variation_key)
      ExperimentRequest.new(
        key: EvaluatorKey.new(type: 'EXPERIMENT', id: experiment.id),
        workspace: workspace,
        user: user,
        experiment: experiment,
        default_variation_key: default_variation_key
      )
    end

    # @param request [EvaluatorRequest]
    # @param experiment [Experiment]
    # @return [Hackle::ExperimentRequest]
    def self.create_by(request, experiment)
      ExperimentRequest.new(
        key: EvaluatorKey.new(type: 'EXPERIMENT', id: experiment.id),
        workspace: request.workspace,
        user: request.user,
        experiment: experiment,
        default_variation_key: 'A'
      )
    end
  end

  class ExperimentEvaluation < EvaluatorEvaluation
    # @return [Experiment]
    attr_reader :experiment

    # @return [Integer, nil]
    attr_reader :variation_id

    # @return [String]
    attr_reader :variation_key

    # @return [ParameterConfiguration, nil]
    attr_reader :config

    # @param reason [String]
    # @param target_evaluations [Array<EvaluatorEvaluation]
    # @param experiment [Experiment]
    # @param variation_id [Integer, nil]
    # @param variation_key [String]
    # @param config [ParameterConfiguration, nil]
    def initialize(reason:, target_evaluations:, experiment:, variation_id:, variation_key:, config:)
      super(reason: reason, target_evaluations: target_evaluations)
      @experiment = experiment
      @variation_id = variation_id
      @variation_key = variation_key
      @config = config
    end

    # @return [ParameterConfig]
    def parameter_config
      return ParameterConfig.empty if @config.nil?

      ParameterConfig.new(@config.parameters)
    end

    # @param reason [String]
    # @return [Hackle::ExperimentEvaluation]
    def with(reason)
      ExperimentEvaluation.new(
        reason: reason,
        target_evaluations: target_evaluations,
        experiment: experiment,
        variation_id: variation_id,
        variation_key: variation_key,
        config: config
      )
    end

    # @param request [ExperimentRequest]
    # @param context [EvaluatorContext]
    # @param variation [Variation]
    # @param reason [String]
    # @return [Hackle::ExperimentEvaluation]
    def self.create(request, context, variation, reason)
      configuration = configuration_or_nil(request.workspace, variation)
      ExperimentEvaluation.new(
        reason: reason,
        target_evaluations: context.evaluations,
        experiment: request.experiment,
        variation_id: variation.id,
        variation_key: variation.key,
        config: configuration
      )
    end

    # @param request [ExperimentRequest]
    # @param context [EvaluatorContext]
    # @param reason [String]
    # @return [Hackle::ExperimentEvaluation]
    def self.create_default(request, context, reason)
      variation = request.experiment.get_variation_or_nil_by_key(request.default_variation_key)
      return create(request, context, variation, reason) unless variation.nil?

      ExperimentEvaluation.new(
        reason: reason,
        target_evaluations: context.evaluations,
        experiment: request.experiment,
        variation_id: nil,
        variation_key: request.default_variation_key,
        config: nil
      )
    end

    # @param workspace [Workspace]
    # @param variation [Variation]
    # @return [Hackle::ParameterConfiguration, nil]
    def self.configuration_or_nil(workspace, variation)
      parameter_configuration_id = variation.parameter_configuration_id
      return nil if parameter_configuration_id.nil?

      workspace.get_parameter_configuration_or_nil(parameter_configuration_id)
    end
  end
end

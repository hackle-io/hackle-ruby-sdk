# frozen_string_literal: true

require 'hackle/internal/model/decision_reason'
require 'hackle/internal/evaluation/evaluator/experiment/experiment_evaluator'

module Hackle
  class ExperimentEvaluatorMatcher
    # @param evaluator [Evaluator]
    def initialize(evaluator:)
      # @type [Evaluator]
      @evaluator = evaluator
    end

    # @param request [EvaluatorRequest]
    # @param context [EvaluatorContext]
    # @param condition [TargetCondition]
    # @return [boolean]
    def matches(request, context, condition)
      key = Integer(condition.key.name, exception: false)
      raise ArgumentError, "invalid key [#{condition.key.type}, #{condition.key.name}]" if key.nil?

      experiment = experiment_or_nil(request, key)
      return false if experiment.nil?

      evaluation = get_evaluation_or_nil(context, experiment)
      evaluation = evaluate(request, context, experiment) if evaluation.nil?

      evaluation_matches(evaluation, condition)
    end

    private

    # @param request [EvaluatorRequest]
    # @param context [EvaluatorContext]
    # @param experiment [Experiment]
    # @return [Hackle::ExperimentEvaluation]
    def evaluate(request, context, experiment)
      experiment_request = ExperimentRequest.create_by(request, experiment)
      evaluation = @evaluator.evaluate(experiment_request, context)
      unless evaluation.is_a?(ExperimentEvaluation)
        raise ArgumentError, "unexpected evaluation: #{evaluation.class} (expected: ExperimentEvaluation)"
      end

      resolved_evaluation = resolve_evaluation(request, evaluation)
      context.add_evaluation(resolved_evaluation)
      resolved_evaluation
    end

    # @param context [EvaluatorContext]
    # @param experiment [Experiment]
    # @return [ExperimentEvaluation, nil]
    def get_evaluation_or_nil(context, experiment)
      context.evaluations.each do |evaluation|
        return evaluation if evaluation.is_a?(ExperimentEvaluation) && evaluation.experiment.id == experiment.id
      end
      nil
    end

    # @abstract
    # @param request [EvaluatorRequest]
    # @param key [Integer]
    # @return [Experiment, nil]
    def experiment_or_nil(request, key) end

    # @abstract
    # @param request [EvaluatorRequest]
    # @param evaluation [ExperimentEvaluation]
    # @return [ExperimentEvaluation]
    def resolve_evaluation(request, evaluation) end

    # @abstract
    # @param evaluation [ExperimentEvaluation]
    # @param condition [TargetCondition]
    # @return [boolean]
    def evaluation_matches(evaluation, condition) end
  end

  class AbTestEvaluatorMatcher < ExperimentEvaluatorMatcher
    # @param evaluator [Evaluator]
    # @param value_operator_matcher [ValueOperatorMatcher]
    def initialize(evaluator:, value_operator_matcher:)
      super(evaluator: evaluator)
      # @type [ValueOperatorMatcher]
      @value_operator_matcher = value_operator_matcher
    end

    def experiment_or_nil(request, key)
      request.workspace.get_experiment_or_nil(key)
    end

    def resolve_evaluation(request, evaluation)
      if request.is_a?(ExperimentRequest) && evaluation.reason == DecisionReason::TRAFFIC_ALLOCATED
        return evaluation.with(DecisionReason::TRAFFIC_ALLOCATED_BY_TARGETING)
      end

      evaluation
    end

    def evaluation_matches(evaluation, condition)
      return false if AB_TEST_MATCHED_REASONS.none?(evaluation.reason)

      @value_operator_matcher.matches(evaluation.variation_key, condition.match)
    end

    AB_TEST_MATCHED_REASONS = [
      DecisionReason::OVERRIDDEN,
      DecisionReason::TRAFFIC_ALLOCATED,
      DecisionReason::TRAFFIC_ALLOCATED_BY_TARGETING,
      DecisionReason::EXPERIMENT_COMPLETED
    ].freeze
  end

  class FeatureFlagEvaluatorMatcher < ExperimentEvaluatorMatcher
    # @param evaluator [Evaluator]
    # @param value_operator_matcher [ValueOperatorMatcher]
    def initialize(evaluator:, value_operator_matcher:)
      super(evaluator: evaluator)
      # @type [ValueOperatorMatcher]
      @value_operator_matcher = value_operator_matcher
    end

    def experiment_or_nil(request, key)
      request.workspace.get_feature_flag_or_nil(key)
    end

    def resolve_evaluation(_request, evaluation)
      evaluation
    end

    def evaluation_matches(evaluation, condition)
      on = evaluation.variation_key != 'A'
      @value_operator_matcher.matches(on, condition.match)
    end
  end
end

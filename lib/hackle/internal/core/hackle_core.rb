# frozen_string_literal: true

require 'hackle/internal/event/user_event'
require 'hackle/internal/model/decision_reason'
require 'hackle/internal/evaluation/evaluator/delegating/delegating_evaluator'
require 'hackle/internal/evaluation/match/condition/condition_matcher_factory'
require 'hackle/internal/evaluation/match/target/target_matcher'
require 'hackle/internal/evaluation/bucketer/bucketer'
require 'hackle/internal/evaluation/evaluator/experiment/experiment_evaluator'
require 'hackle/internal/evaluation/evaluator/experiment/experiment_evaluation_flow_factory'
require 'hackle/internal/evaluation/evaluator/remoteconfig/remote_config_evaluator'
require 'hackle/internal/evaluation/evaluator/remoteconfig/remote_config_determiner'
require 'hackle/internal/event/user_event_factory'
require 'hackle/internal/clock/clock'

module Hackle
  class Core

    # @param experiment_evaluator [ExperimentEvaluator]
    # @param remote_config_evaluator [RemoteConfigEvaluator]
    # @param workspace_fetcher [WorkspaceFetcher]
    # @param event_factory [UserEventFactory]
    # @param event_processor [UserEventProcessor]
    # @param clock [Clock]
    def initialize(
      experiment_evaluator:,
      remote_config_evaluator:,
      workspace_fetcher:,
      event_factory:,
      event_processor:,
      clock:
    )
      # @type experiment_evaluator [ExperimentEvaluator]
      @experiment_evaluator = experiment_evaluator
      # @type remote_config_evaluator [RemoteConfigEvaluator]
      @remote_config_evaluator = remote_config_evaluator
      # @type workspace_fetcher [WorkspaceFetcher]
      @workspace_fetcher = workspace_fetcher
      # @type event_factory [UserEventFactory]
      @event_factory = event_factory
      # @type event_processor [UserEventProcessor]
      @event_processor = event_processor
      # @type clock [Clock]
      @clock = clock
    end

    # @param workspace_fetcher [WorkspaceFetcher]
    # @param event_processor [UserEventProcessor]
    # @return [Core]
    def self.create(workspace_fetcher:, event_processor:)
      delegating_evaluator = DelegatingEvaluator.new

      condition_matcher_factory = ConditionMatcherFactory.new(evaluator: delegating_evaluator)
      target_matcher = TargetMatcher.new(condition_matcher_factory: condition_matcher_factory)
      bucketer = Bucketer.new(hasher: Hasher.new)

      experiment_evaluator = ExperimentEvaluator.new(
        flow_factory: ExperimentEvaluationFlowFactory.new(
          target_matcher: target_matcher,
          bucketer: bucketer
        )
      )
      delegating_evaluator.add(experiment_evaluator)

      remote_config_evaluator = RemoteConfigEvaluator.new(
        target_rule_determiner: RemoteConfigTargetRuleDeterminer.new(
          matcher: RemoteConfigTargetRuleMatcher.new(
            target_matcher: target_matcher,
            bucketer: bucketer
          )
        )
      )
      delegating_evaluator.add(remote_config_evaluator)

      Core.new(
        experiment_evaluator: experiment_evaluator,
        remote_config_evaluator: remote_config_evaluator,
        workspace_fetcher: workspace_fetcher,
        event_factory: UserEventFactory.new(clock: SystemClock.instance),
        event_processor: event_processor,
        clock: SystemClock.instance
      )
    end

    # @param experiment_key [Integer]
    # @param user [HackleUser]
    # @param default_variation [String]
    # @return [ExperimentDecision]
    def experiment(experiment_key, user, default_variation)
      workspace = @workspace_fetcher.fetch
      return ExperimentDecision.new(default_variation, DecisionReason::SDK_NOT_READY, ParameterConfig.empty) if workspace.nil?

      experiment = workspace.get_experiment_or_nil(experiment_key)
      return ExperimentDecision.new(default_variation, DecisionReason::EXPERIMENT_NOT_FOUND, ParameterConfig.empty) if experiment.nil?

      request = ExperimentRequest.create(workspace, user, experiment, default_variation)
      evaluation = @experiment_evaluator.evaluate(request, Evaluator.context)

      events = @event_factory.create(request, evaluation)
      events.each do |event|
        @event_processor.process(event)
      end

      ExperimentDecision.new(evaluation.variation_key, evaluation.reason, evaluation.parameter_config)
    end

    # @param feature_key [Integer]
    # @param user [HackleUser]
    # @return [FeatureFlagDecision]
    def feature_flag(feature_key, user)
      workspace = @workspace_fetcher.fetch
      return FeatureFlagDecision.new(false, DecisionReason::SDK_NOT_READY, ParameterConfig.empty) if workspace.nil?

      feature_flag = workspace.get_feature_flag_or_nil(feature_key)
      return FeatureFlagDecision.new(false, DecisionReason::FEATURE_FLAG_NOT_FOUND, ParameterConfig.empty) if feature_flag.nil?

      request = ExperimentRequest.create(workspace, user, feature_flag, 'A')
      evaluation = @experiment_evaluator.evaluate(request, Evaluator.context)

      events = @event_factory.create(request, evaluation)
      events.each do |event|
        @event_processor.process(event)
      end

      is_on = evaluation.variation_key != 'A'
      FeatureFlagDecision.new(is_on, evaluation.reason, evaluation.parameter_config)
    end

    # @param parameter_key [String]
    # @param user [HackleUser]
    # @param required_type [ValueType]
    # @param default_value [Object, nil]
    def remote_config(parameter_key, user, required_type, default_value)
      workspace = @workspace_fetcher.fetch
      return RemoteConfigDecision.new(default_value, DecisionReason::SDK_NOT_READY) if workspace.nil?

      parameter = workspace.get_remote_config_parameter_or_nil(parameter_key)
      return RemoteConfigDecision.new(default_value, DecisionReason::REMOTE_CONFIG_PARAMETER_NOT_FOUND) if parameter.nil?

      request = RemoteConfigRequest.create(workspace, user, parameter, required_type, default_value)
      evaluation = @remote_config_evaluator.evaluate(request, Evaluator.context)

      events = @event_factory.create(request, evaluation)
      events.each do |event|
        @event_processor.process(event)
      end

      RemoteConfigDecision.new(evaluation.value, evaluation.reason)
    end

    # @param event [Event]
    # @param user [HackleUser]
    def track(event, user)
      event_type = event_type(event)
      @event_processor.process(UserEvent.track(event_type, event, user, @clock.current_millis))
    end

    def close
      @workspace_fetcher.stop
      @event_processor.stop
    end

    private

    # @param event [Event]
    # @return [EventType]
    def event_type(event)
      workspace = @workspace_fetcher.fetch
      return EventType.new(id: 0, key: event.key) if workspace.nil?

      event_type = workspace.get_event_type_or_nil(event.key)
      return EventType.new(id: 0, key: event.key) if event_type.nil?

      event_type
    end
  end
end

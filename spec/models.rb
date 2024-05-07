# frozen_string_literal: true

require 'rspec'
require 'hackle/user'
require 'hackle/event'
require 'hackle/decision'
require 'hackle/internal/config/parameter_config'
require 'hackle/internal/clock/clock'
require 'hackle/internal/model/sdk'
require 'hackle/internal/model/container'
require 'hackle/internal/model/target'
require 'hackle/internal/model/experiment'
require 'hackle/internal/model/variation'
require 'hackle/internal/model/action'
require 'hackle/internal/model/value_type'
require 'hackle/internal/model/remote_config_parameter'
require 'hackle/internal/workspace/workspace'
require 'hackle/internal/user/hackle_user'
require 'hackle/internal/event/user_event'
require 'hackle/internal/evaluation/evaluator/experiment/experiment_evaluator'
require 'hackle/internal/evaluation/evaluator/remoteconfig/remote_config_evaluator'
require 'hackle/internal/evaluation/evaluator/evaluator'
require 'hackle/internal/concurrent/executors'
require 'hackle/internal/properties/properties_builder'

module Hackle
  class Experiments
    def self.request(
      workspace: Workspace.create,
      user: HackleUser.builder.identifier('$id', '42').build,
      experiment: create,
      default_variation_key: 'A'
    )
      ExperimentRequest.create(workspace, user, experiment, default_variation_key)
    end

    def self.create(
      id: 1,
      key: 1,
      type: ExperimentType::AB_TEST,
      identifier_type: '$id',
      status: ExperimentStatus::RUNNING,
      version: 1,
      execution_version: 1,
      variations: [variation(id: 1, key: 'A'), variation(id: 2, key: 'B')],
      user_overrides: {},
      segment_overrides: [],
      target_audiences: [],
      target_rules: [],
      container_id: nil,
      winner_variation_id: nil
    )
      Experiment.new(
        id: id,
        key: key,
        name: nil,
        type: type,
        identifier_type: identifier_type,
        status: status,
        version: version,
        execution_version: execution_version,
        variations: variations,
        user_overrides: user_overrides,
        segment_overrides: segment_overrides,
        target_audiences: target_audiences,
        target_rules: target_rules,
        default_rule: Action.new(type: ActionType::BUCKET, variation_id: nil, bucket_id: 1),
        container_id: container_id,
        winner_variation_id: winner_variation_id
      )
    end

    def self.variation(
      id: 1,
      key: 'A',
      is_dropped: false,
      parameter_configuration_id: nil
    )
      Variation.new(id: id, key: key, is_dropped: is_dropped, parameter_configuration_id: parameter_configuration_id)
    end
  end

  class RemoteConfigs
    def self.parameter(
      id: 1,
      key: 'remote_config_parameter',
      type: ValueType::STRING,
      identifier_type: '$id',
      target_rules: [],
      default_value: RemoteConfigValue.new(id: 1, raw_value: 'parameter_default_value')
    )
      RemoteConfigParameter.new(
        id: id,
        key: key,
        type: type,
        identifier_type: identifier_type,
        target_rules: target_rules,
        default_value: default_value
      )
    end

    def self.target_rule(
      key: 'key',
      name: 'name',
      target: Target.new(conditions: []),
      bucket_id: 1,
      value: RemoteConfigValue.new(id: 1, raw_value: 'target_value')
    )
      RemoteConfigTargetRule.new(
        key: key,
        name: name,
        target: target,
        bucket_id: bucket_id,
        value: value
      )
    end

    def self.request(
      workspace: Workspace.create,
      user: HackleUser.builder.identifier('$id', '42').build,
      parameter: RemoteConfigs.parameter,
      required_type: ValueType::STRING,
      default_value: 'sdk_default_value'
    )
      RemoteConfigRequest.create(workspace, user, parameter, required_type, default_value)
    end
  end

  class Evaluators
    def self.request(
      type: 'test',
      id: 1,
      workspace: Workspace.create,
      user: HackleUser.builder.identifier('$id', 'user').build
    )
      EvaluatorRequest.new(
        key: EvaluatorKey.new(
          type: type,
          id: id
        ),
        workspace: workspace,
        user: user
      )
    end

    def self.evaluation(
      reason: 'reason',
      target_evaluation: []
    )
      EvaluatorEvaluation.new(
        reason: reason,
        target_evaluations: target_evaluation
      )
    end
  end

  class UserEvents
    def self.track(
      key:,
      user: HackleUser.builder.identifier('$id', 'user').build,
      timestamp: 42
    )
      UserEvent.track(
        EventType.new(id: 1, key: key),
        Event.builder(key).build,
        user,
        timestamp
      )
    end
  end
end

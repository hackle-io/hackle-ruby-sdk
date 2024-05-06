# frozen_string_literal: true

require 'hackle/internal/model/action'
require 'hackle/internal/model/bucket'
require 'hackle/internal/model/container'
require 'hackle/internal/model/event_type'
require 'hackle/internal/model/experiment'
require 'hackle/internal/model/parameter_configuration'
require 'hackle/internal/model/remote_config_parameter'
require 'hackle/internal/model/segment'
require 'hackle/internal/model/target'
require 'hackle/internal/model/target_rule'
require 'hackle/internal/model/targeting'
require 'hackle/internal/model/value_type'
require 'hackle/internal/model/variation'

module Hackle
  class Workspace
    # @param experiments [Hash{Integer => Experiment}]
    # @param feature_flags [Hash{Integer => Experiment}]
    # @param buckets [Hash{Integer => Bucket}]
    # @param event_types [Hash{String => EventType}]
    # @param segments [Hash{String => Segment}]
    # @param containers [Hash{Integer => Container}]
    # @param parameter_configurations [Hash{Integer => ParameterConfiguration}]
    # @param remote_config_parameters [Hash{String => RemoteConfigParameter}]
    def initialize(
      experiments:,
      feature_flags:,
      buckets:,
      event_types:,
      segments:,
      containers:,
      parameter_configurations:,
      remote_config_parameters:
    )
      # @type [Hash{Integer => Experiment}]
      @experiments = experiments

      # @type [Hash{Integer => Experiment}]
      @feature_flags = feature_flags

      # @type [Hash{Integer => Bucket}]
      @buckets = buckets

      # @type [Hash{String => EventType}]
      @event_types = event_types

      # @type [Hash{String => Segment}]
      @segments = segments

      # @type [Hash{Integer => Container}]
      @containers = containers

      # @type [Hash{Integer => ParameterConfiguration}]
      @parameter_configurations = parameter_configurations

      # @type [Hash{String => RemoteConfigParameter}]
      @remote_config_parameters = remote_config_parameters
    end

    # @param experiment_key [Integer]
    # @return [Hackle::Experiment, nil]
    def get_experiment_or_nil(experiment_key)
      @experiments[experiment_key]
    end

    # @param feature_key [Integer]
    # @return [Hackle::Experiment, nil]
    def get_feature_flag_or_nil(feature_key)
      @feature_flags[feature_key]
    end

    # @param event_type_key [String]
    # @return [Hackle::EventType, nil]
    def get_event_type_or_nil(event_type_key)
      @event_types[event_type_key]
    end

    # @param bucket_id [Integer]
    # @return [Hackle::Bucket, nil]
    def get_bucket_or_nil(bucket_id)
      @buckets[bucket_id]
    end

    # @param segment_key [String]
    # @return [Hackle::Segment, nil]
    def get_segment_or_nil(segment_key)
      @segments[segment_key]
    end

    # @param container_id [Integer]
    # @return [Hackle::Container, nil]
    def get_container_or_nil(container_id)
      @containers[container_id]
    end

    # @param parameter_configuration_id [Integer]
    # @return [Hackle::ParameterConfiguration, nil]
    def get_parameter_configuration_or_nil(parameter_configuration_id)
      @parameter_configurations[parameter_configuration_id]
    end

    # @param parameter_key [String]
    # @return [Hackle::RemoteConfigParameter, nil]
    def get_remote_config_parameter_or_nil(parameter_key)
      @remote_config_parameters[parameter_key]
    end

    class << self
      # @param experiments [Array<Experiment>]
      # @param feature_flags [Array<Experiment>]
      # @param buckets [Array<Bucket>]
      # @param event_types [Array<EventType>]
      # @param segments [Array<Segment>]
      # @param containers [Array<Container>]
      # @param parameter_configurations [Array<ParameterConfiguration>]
      # @param remote_config_parameters [Array<RemoteConfigParameter>]
      # @return [Workspace]
      def create(
        experiments: [],
        feature_flags: [],
        buckets: [],
        event_types: [],
        segments: [],
        containers: [],
        parameter_configurations: [],
        remote_config_parameters: []
      )
        Workspace.new(
          experiments: experiments.each_with_object({}) { |item, hash| hash[item.key] = item },
          feature_flags: feature_flags.each_with_object({}) { |item, hash| hash[item.key] = item },
          buckets: buckets.each_with_object({}) { |item, hash| hash[item.id] = item },
          event_types: event_types.each_with_object({}) { |item, hash| hash[item.key] = item },
          segments: segments.each_with_object({}) { |item, hash| hash[item.key] = item },
          containers: containers.each_with_object({}) { |item, hash| hash[item.id] = item },
          parameter_configurations: parameter_configurations.each_with_object({}) { |item, hash| hash[item.id] = item },
          remote_config_parameters: remote_config_parameters.each_with_object({}) { |item, hash| hash[item.key] = item }
        )
      end

      # @param hash [Hash]
      # @return [Hackle::Workspace]
      def from_hash(hash)
        Workspace.create(
          experiments: hash[:experiments].map { |it| experiment(it, ExperimentType::AB_TEST) },
          feature_flags: hash[:featureFlags].map { |it| experiment(it, ExperimentType::FEATURE_FLAG) },
          buckets: hash[:buckets].map { |it| bucket(it) },
          event_types: hash[:events].map { |it| event_type(it) },
          segments: hash[:segments].map { |it| segment_or_nil(it) }.compact,
          containers: hash[:containers].map { |it| container(it) },
          parameter_configurations: hash[:parameterConfigurations].map { |it| parameter_configuration(it) },
          remote_config_parameters: hash[:remoteConfigParameters].map { |it| remote_config_parameter_or_nil(it) }.compact
        )
      end

      private

      def experiment(hash, experiment_type)
        status = ExperimentStatus.from_or_nil(hash[:execution][:status])
        return nil if status.nil?

        default_rule = action_or_nil(hash[:execution][:defaultRule])
        return nil if default_rule.nil?

        Experiment.new(
          id: hash[:id],
          key: hash[:key],
          name: hash[:name],
          type: experiment_type,
          identifier_type: hash[:identifierType],
          status: status,
          version: hash[:version],
          execution_version: hash[:execution][:version],
          variations: hash[:variations].map { |it| variation(it) },
          user_overrides: Hash[hash[:execution][:userOverrides].map { |it| [it[:userId], it[:variationId]] }],
          segment_overrides: hash[:execution][:segmentOverrides].map { |it| target_rule_or_nil(it, TargetingType::IDENTIFIER) }.compact,
          target_audiences: hash[:execution][:targetAudiences].map { |it| target_or_nil(it, TargetingType::PROPERTY) }.compact,
          target_rules: hash[:execution][:targetRules].map { |it| target_rule_or_nil(it, TargetingType::PROPERTY) }.compact,
          default_rule: default_rule,
          container_id: hash[:containerId],
          winner_variation_id: hash[:winnerVariationId]
        )
      end

      def variation(hash)
        Variation.new(
          id: hash[:id],
          key: hash[:key],
          is_dropped: hash[:status] == 'DROPPED',
          parameter_configuration_id: hash[:parameterConfigurationId]
        )
      end

      def target_or_nil(hash, targeting_type)
        conditions = hash[:conditions].map { |it| condition_or_nil(it, targeting_type) }.compact
        return nil if conditions.empty?

        Target.new(conditions: conditions)
      end

      def condition_or_nil(hash, targeting_type)
        key = target_key_or_nil(hash[:key])
        return nil if key.nil?
        return nil unless targeting_type.supports?(key.type)

        match = target_match_or_nil(hash[:match])
        return nil if match.nil?

        TargetCondition.new(
          key: key,
          match: match
        )
      end

      def target_key_or_nil(hash)
        type = TargetKeyType.from_or_nil(hash[:type])
        return nil if type.nil?

        TargetKey.new(
          type: type,
          name: hash[:name]
        )
      end

      def target_match_or_nil(hash)
        type = TargetMatchType.from_or_nil(hash[:type])
        return nil if type.nil?

        operator = TargetOperator.from_or_nil(hash[:operator])
        return nil if operator.nil?

        value_type = ValueType.from_or_nil(hash[:valueType])
        return nil if value_type.nil?

        TargetMatch.new(
          type: type,
          operator: operator,
          value_type: value_type,
          values: hash[:values]
        )
      end

      def action_or_nil(hash)
        type = ActionType.from_or_nil(hash[:type])
        return nil if type.nil?

        Action.new(
          type: type,
          variation_id: hash[:variationId],
          bucket_id: hash[:bucketId]
        )
      end

      def target_rule_or_nil(hash, targeting_type)
        target = target_or_nil(hash[:target], targeting_type)
        return nil if target.nil?

        action = action_or_nil(hash[:action])
        return nil if action.nil?

        TargetRule.new(
          target: target,
          action: action
        )
      end

      def bucket(hash)
        Bucket.new(
          id: hash[:id],
          seed: hash[:seed],
          slot_size: hash[:slotSize],
          slots: hash[:slots].map { |it| slot(it) }
        )
      end

      def slot(hash)
        Slot.new(
          start_inclusive: hash[:startInclusive],
          end_exclusive: hash[:endExclusive],
          variation_id: hash[:variationId]
        )
      end

      def event_type(hash)
        EventType.new(
          id: hash[:id],
          key: hash[:key]
        )
      end

      def segment_or_nil(hash)
        type = SegmentType.from_or_nil(hash[:type])
        return nil if type.nil?

        Segment.new(
          id: hash[:id],
          key: hash[:key],
          type: type,
          targets: hash[:targets].map { |it| target_or_nil(it, TargetingType::SEGMENT) }.compact
        )
      end

      def container(hash)
        Container.new(
          id: hash[:id],
          bucket_id: hash[:bucketId],
          groups: hash[:groups].map { |it| ContainerGroup.new(id: it[:id], experiments: it[:experiments]) }
        )
      end

      def parameter_configuration(hash)
        ParameterConfiguration.new(
          id: hash[:id],
          parameters: Hash[hash[:parameters].map { |it| [it[:key], it[:value]] }]
        )
      end

      def remote_config_parameter_or_nil(hash)
        type = ValueType.from_or_nil(hash[:type])
        return nil if type.nil?

        RemoteConfigParameter.new(
          id: hash[:id],
          key: hash[:key],
          type: type,
          identifier_type: hash[:identifierType],
          target_rules: hash[:targetRules].map { |it| remote_config_target_rule_or_nil(it) }.compact,
          default_value: RemoteConfigValue.new(
            id: hash[:defaultValue][:id],
            raw_value: hash[:defaultValue][:value],
          )
        )
      end

      def remote_config_target_rule_or_nil(hash)
        target = target_or_nil(hash[:target], TargetingType::PROPERTY)
        return nil if target.nil?

        RemoteConfigTargetRule.new(
          key: hash[:key],
          name: hash[:name],
          target: target,
          bucket_id: hash[:bucketId],
          value: RemoteConfigValue.new(
            id: hash[:value][:id],
            raw_value: hash[:value][:value]
          )
        )
      end
    end
  end
end

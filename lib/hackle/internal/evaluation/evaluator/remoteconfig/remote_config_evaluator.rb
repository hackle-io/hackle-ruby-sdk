# frozen_string_literal: true

require 'hackle/internal/model/value_type'
require 'hackle/internal/model/decision_reason'
require 'hackle/internal/properties/properties_builder'

module Hackle
  class RemoteConfigEvaluator
    include ContextualEvaluator

    # @param target_rule_determiner [RemoteConfigTargetRuleDeterminer]
    def initialize(target_rule_determiner:)
      # @type [RemoteConfigTargetRuleDeterminer]
      @target_rule_determiner = target_rule_determiner
    end

    def supports?(request)
      request.is_a?(RemoteConfigRequest)
    end

    # @param request [RemoteConfigRequest]
    # @param context [EvaluatorContext]
    # @return [RemoteConfigEvaluation]
    def evaluate_internal(request, context)
      properties_builder = PropertiesBuilder.new
                                            .add('requestValueType', request.required_type.name)
                                            .add('requestDefaultValue', request.default_value)

      if request.user.identifiers[request.parameter.identifier_type].nil?
        return RemoteConfigEvaluation.create_default(
          request, context, DecisionReason::IDENTIFIER_NOT_FOUND, properties_builder
        )
      end

      target_rule = @target_rule_determiner.determine_or_nil(request, context)
      unless target_rule.nil?
        properties_builder.add('targetRuleKey', target_rule.key)
        properties_builder.add('targetRuleName', target_rule.name)
        return evaluation(request, context, target_rule.value, DecisionReason::TARGET_RULE_MATCH, properties_builder)
      end

      evaluation(request, context, request.parameter.default_value, DecisionReason::DEFAULT_RULE, properties_builder)
    end

    private

    # @param request [RemoteConfigRequest]
    # @param context [EvaluatorContext]
    # @param parameter_value [RemoteConfigValue]
    # @param reason [String]
    # @param properties_builder [PropertiesBuilder]
    # @return [RemoteConfigEvaluation]
    def evaluation(request, context, parameter_value, reason, properties_builder)
      if valid?(request.required_type, parameter_value.raw_value)
        RemoteConfigEvaluation.create(request, context, parameter_value.id, parameter_value.raw_value, reason,
                                      properties_builder)
      else
        RemoteConfigEvaluation.create_default(request, context, DecisionReason::TYPE_MISMATCH, properties_builder)
      end
    end

    # @param required_type [ValueType]
    # @param value [Object]
    # @return [boolean]
    def valid?(required_type, value)
      case required_type
      when ValueType::NULL
        true
      when ValueType::STRING
        value.is_a?(String)
      when ValueType::NUMBER
        value.is_a?(Numeric)
      when ValueType::BOOLEAN
        value.is_a?(TrueClass) || value.is_a?(FalseClass)
      else
        false
      end
    end
  end

  class RemoteConfigRequest < EvaluatorRequest
    # @return [RemoteConfigParameter]
    attr_reader :parameter

    # @return [ValueType]
    attr_reader :required_type

    # @return [Object, nil]
    attr_reader :default_value

    # @param key [EvaluatorKey]
    # @param workspace [Workspace]
    # @param user [HackleUser]
    # @param parameter [RemoteConfigParameter]
    # @param required_type [ValueType]
    # @param default_value [Object, nil]
    def initialize(key:, workspace:, user:, parameter:, required_type:, default_value:)
      super(key: key, workspace: workspace, user: user)
      @parameter = parameter
      @required_type = required_type
      @default_value = default_value
    end

    # @param workspace [Workspace]
    # @param user [HackleUser]
    # @param parameter [RemoteConfigParameter]
    # @param required_type [ValueType]
    # @param default_value [Object, nil]
    def self.create(workspace, user, parameter, required_type, default_value)
      RemoteConfigRequest.new(
        key: EvaluatorKey.new(type: 'REMOTE_CONFIG', id: parameter.id),
        workspace: workspace,
        user: user,
        parameter: parameter,
        required_type: required_type,
        default_value: default_value
      )
    end
  end

  class RemoteConfigEvaluation < EvaluatorEvaluation
    # @return [RemoteConfigParameter]
    attr_reader :parameter

    # @return [Integer, nil]
    attr_reader :value_id

    # @return [Object]
    attr_reader :value

    # @return [Hash<String => Object>]
    attr_reader :properties

    # @param reason [String]
    # @param target_evaluations [Array<EvaluatorEvaluation>]
    # @param parameter [RemoteConfigParameter]
    # @param value_id [Integer, nil]
    # @param value [Object, nil]
    # @param properties [Hash<String => Object>]
    def initialize(reason:, target_evaluations:, parameter:, value_id:, value:, properties:)
      super(reason: reason, target_evaluations: target_evaluations)
      @parameter = parameter
      @value_id = value_id
      @value = value
      @properties = properties
    end

    # @param request [RemoteConfigRequest]
    # @param context [EvaluatorContext]
    # @param value_id [Integer, nil]
    # @param value [Object, nil]
    # @param reason [String]
    # @param properties_builder [PropertiesBuilder]
    def self.create(request, context, value_id, value, reason, properties_builder)
      properties_builder.add('returnValue', value)
      RemoteConfigEvaluation.new(
        reason: reason,
        target_evaluations: context.evaluations,
        parameter: request.parameter,
        value_id: value_id,
        value: value,
        properties: properties_builder.build
      )
    end

    # @param request [RemoteConfigRequest]
    # @param context [EvaluatorContext]
    # @param reason [String]
    # @param properties_builder [PropertiesBuilder]
    def self.create_default(request, context, reason, properties_builder)
      create(request, context, nil, request.default_value, reason, properties_builder)
    end
  end
end

# frozen_string_literal: true

require 'rspec'
require 'models'
require 'hackle/internal/evaluation/evaluator/remoteconfig/remote_config_evaluator'

module Hackle
  describe RemoteConfigEvaluator do
    before do
      @target_rule_determiner = double
      @sut = RemoteConfigEvaluator.new(target_rule_determiner: @target_rule_determiner)
    end

    it 'supports' do
      expect(@sut.supports?(RemoteConfigs.request)).to eq(true)
      expect(@sut.supports?(Experiments.request)).to eq(false)
    end

    it 'when identifier not found then return default value' do
      parameter = RemoteConfigs.parameter(
        id: 42,
        identifier_type: 'custom_id'
      )
      request = RemoteConfigs.request(
        user: HackleUser.builder.identifier('$id', 'user').build,
        parameter: parameter,
        required_type: ValueType::STRING,
        default_value: 'default'
      )
      context = Evaluator.context

      actual = @sut.evaluate(request, context)

      expect(actual.reason).to eq('IDENTIFIER_NOT_FOUND')
      expect(actual.value).to eq('default')
      expect(actual.properties).to eq({
                                        'requestValueType' => 'STRING',
                                        'requestDefaultValue' => 'default',
                                        'returnValue' => 'default'
                                      })
    end

    it 'when target rule determined then return determined value' do
      target_rule = RemoteConfigs.target_rule(
        key: 'target_rule_key',
        name: 'target_rule_name',
        value: RemoteConfigValue.new(
          id: 320,
          raw_value: 'target_rule_value'
        )
      )
      parameter = RemoteConfigs.parameter(
        id: 42,
        type: ValueType::STRING,
        identifier_type: '$id',
        target_rules: [target_rule]
      )
      request = RemoteConfigs.request(
        user: HackleUser.builder.identifier('$id', 'user').build,
        parameter: parameter,
        required_type: ValueType::STRING,
        default_value: 'default'
      )
      context = Evaluator.context
      allow(@target_rule_determiner).to receive(:determine_or_nil).and_return(target_rule)

      actual = @sut.evaluate(request, context)

      expect(actual.reason).to eq('TARGET_RULE_MATCH')
      expect(actual.value_id).to eq(320)
      expect(actual.value).to eq('target_rule_value')
      expect(actual.properties).to eq({
                                        'requestValueType' => 'STRING',
                                        'requestDefaultValue' => 'default',
                                        'returnValue' => 'target_rule_value',
                                        'targetRuleKey' => 'target_rule_key',
                                        'targetRuleName' => 'target_rule_name'
                                      })
    end

    it 'when target rule not determined then return parameter default value' do
      target_rule = RemoteConfigs.target_rule(
        key: 'target_rule_key',
        name: 'target_rule_name',
        value: RemoteConfigValue.new(
          id: 320,
          raw_value: 'target_rule_value'
        )
      )
      parameter = RemoteConfigs.parameter(
        id: 42,
        type: ValueType::STRING,
        identifier_type: '$id',
        target_rules: [target_rule],
        default_value: RemoteConfigValue.new(
          id: 1001,
          raw_value: 'parameter_default'
        )
      )
      request = RemoteConfigs.request(
        user: HackleUser.builder.identifier('$id', 'user').build,
        parameter: parameter,
        required_type: ValueType::STRING,
        default_value: 'default'
      )
      context = Evaluator.context
      allow(@target_rule_determiner).to receive(:determine_or_nil).and_return(nil)

      actual = @sut.evaluate(request, context)

      expect(actual.reason).to eq('DEFAULT_RULE')
      expect(actual.value_id).to eq(1001)
      expect(actual.value).to eq('parameter_default')
      expect(actual.properties).to eq({
                                        'requestValueType' => 'STRING',
                                        'requestDefaultValue' => 'default',
                                        'returnValue' => 'parameter_default'
                                      })
    end

    it 'when type mismatch then return default value' do
      target_rule = RemoteConfigs.target_rule(
        key: 'target_rule_key',
        name: 'target_rule_name',
        value: RemoteConfigValue.new(
          id: 320,
          raw_value: 'target_rule_value'
        )
      )
      parameter = RemoteConfigs.parameter(
        id: 42,
        type: ValueType::STRING,
        identifier_type: '$id',
        target_rules: [target_rule],
        default_value: RemoteConfigValue.new(
          id: 1001,
          raw_value: 123.45
        )
      )
      request = RemoteConfigs.request(
        user: HackleUser.builder.identifier('$id', 'user').build,
        parameter: parameter,
        required_type: ValueType::STRING,
        default_value: 'default'
      )
      context = Evaluator.context
      allow(@target_rule_determiner).to receive(:determine_or_nil).and_return(nil)

      actual = @sut.evaluate(request, context)

      expect(actual.reason).to eq('TYPE_MISMATCH')
      expect(actual.value_id).to eq(nil)
      expect(actual.value).to eq('default')
      expect(actual.properties).to eq({
                                        'requestValueType' => 'STRING',
                                        'requestDefaultValue' => 'default',
                                        'returnValue' => 'default'
                                      })
    end

    it 'NULL' do
      parameter = RemoteConfigs.parameter(
        id: 42,
        type: ValueType::STRING,
        identifier_type: '$id',
        target_rules: [],
        default_value: RemoteConfigValue.new(
          id: 1001,
          raw_value: 'parameter_default_value'
        )
      )
      request = RemoteConfigs.request(
        user: HackleUser.builder.identifier('$id', 'user').build,
        parameter: parameter,
        required_type: ValueType::NULL,
        default_value: nil
      )
      context = Evaluator.context
      allow(@target_rule_determiner).to receive(:determine_or_nil).and_return(nil)

      actual = @sut.evaluate(request, context)

      expect(actual.reason).to eq('DEFAULT_RULE')
      expect(actual.value_id).to eq(1001)
      expect(actual.value).to eq('parameter_default_value')
    end

    def type_test(request_value_type, request_default_value, parameter_default_value, reason = 'TYPE_MISMATCH')
      parameter = RemoteConfigs.parameter(
        id: 42,
        type: ValueType::STRING,
        identifier_type: '$id',
        target_rules: [],
        default_value: RemoteConfigValue.new(
          id: 1001,
          raw_value: parameter_default_value
        )
      )
      request = RemoteConfigs.request(
        user: HackleUser.builder.identifier('$id', 'user').build,
        parameter: parameter,
        required_type: request_value_type,
        default_value: request_default_value
      )
      context = Evaluator.context
      allow(@target_rule_determiner).to receive(:determine_or_nil).and_return(nil)

      actual = @sut.evaluate(request, context)

      expect(actual.reason).to eq(reason)
      expect(actual.value_id).to eq(nil)
      expect(actual.value).to eq(request_default_value)
    end

    it 'type mismatch' do
      type_test(ValueType::STRING, '42', 42)
      type_test(ValueType::STRING, '42', true)
      type_test(ValueType::STRING, '42', false)

      type_test(ValueType::NUMBER, 42, '42')
      type_test(ValueType::NUMBER, 42, false)
      type_test(ValueType::NUMBER, 42, true)

      type_test(ValueType::BOOLEAN, true, 1)
      type_test(ValueType::BOOLEAN, true, 0)
      type_test(ValueType::BOOLEAN, false, 1)
      type_test(ValueType::BOOLEAN, false, 0)

      type_test(ValueType::BOOLEAN, true, 'false')
      type_test(ValueType::BOOLEAN, false, 'true')

      type_test(ValueType::UNKNOWN, { 'a' => 'b' }, 42)
    end
  end
end

# frozen_string_literal: true

require 'rspec'
require 'models'
require 'hackle/internal/evaluation/evaluator/remoteconfig/remote_config_determiner'

module Hackle
  RSpec.describe RemoteConfigTargetRuleDeterminer do
    before do
      @matcher = instance_double(RemoteConfigTargetRuleMatcher)
      @sut = RemoteConfigTargetRuleDeterminer.new(matcher: @matcher)
    end

    it 'when target rule is empty then return nil' do
      parameter = RemoteConfigs.parameter(target_rules: [])
      request = RemoteConfigs.request(parameter: parameter)
      context = Evaluator.context

      actual = @sut.determine_or_nil(request, context)

      expect(actual).to be(nil)
    end

    it 'when all target rule do not matched then return nil' do
      parameter = RemoteConfigs.parameter(
        target_rules: [
          RemoteConfigs.target_rule(key: '10001'),
          RemoteConfigs.target_rule(key: '10002'),
          RemoteConfigs.target_rule(key: '10003'),
          RemoteConfigs.target_rule(key: '10004'),
          RemoteConfigs.target_rule(key: '10005')
        ]
      )
      request = RemoteConfigs.request(parameter: parameter)
      context = Evaluator.context

      allow(@matcher).to receive(:matches).and_return(false, false, false, false, false)

      actual = @sut.determine_or_nil(request, context)

      expect(actual).to be(nil)
      expect(@matcher).to have_received(:matches).exactly(5).times
    end

    it 'when target rule matched first then return that target rule' do
      parameter = RemoteConfigs.parameter(
        target_rules: [
          RemoteConfigs.target_rule(key: '10001'),
          RemoteConfigs.target_rule(key: '10002'),
          RemoteConfigs.target_rule(key: '10003'),
          RemoteConfigs.target_rule(key: '10004'),
          RemoteConfigs.target_rule(key: '10005')
        ]
      )
      request = RemoteConfigs.request(parameter: parameter)
      context = Evaluator.context

      allow(@matcher).to receive(:matches).and_return(false, false, false, true, false)

      actual = @sut.determine_or_nil(request, context)

      expect(actual.key).to be('10004')
      expect(@matcher).to have_received(:matches).exactly(4).times
    end
  end

  RSpec.describe RemoteConfigTargetRuleMatcher do
    before do
      @target_matcher = double
      @bucketer = double
      @sut = RemoteConfigTargetRuleMatcher.new(target_matcher: @target_matcher, bucketer: @bucketer)
    end

    it 'when not matched then return false' do
      target_rule = RemoteConfigs.target_rule(bucket_id: 320)
      parameter = RemoteConfigs.parameter(
        id: 42,
        identifier_type: '$id',
        target_rules: [target_rule]
      )
      request = RemoteConfigs.request(parameter: parameter)
      context = Evaluator.context

      allow(@target_matcher).to receive(:matches).and_return(false)

      expect(@sut.matches(request, context, target_rule)).to be(false)
    end

    it 'when identifier not found then return false' do
      target_rule = RemoteConfigs.target_rule(bucket_id: 320)
      parameter = RemoteConfigs.parameter(
        id: 42,
        identifier_type: 'custom_id',
        target_rules: [target_rule]
      )
      request = RemoteConfigs.request(
        user: HackleUser.builder.identifier('$id', 'user').build,
        parameter: parameter
      )
      context = Evaluator.context

      allow(@target_matcher).to receive(:matches).and_return(true)

      expect(@sut.matches(request, context, target_rule)).to be(false)
    end

    it 'when bucket not found then raise error' do
      target_rule = RemoteConfigs.target_rule(bucket_id: 320)
      parameter = RemoteConfigs.parameter(
        id: 42,
        identifier_type: '$id',
        target_rules: [target_rule]
      )
      request = RemoteConfigs.request(
        user: HackleUser.builder.identifier('$id', 'user').build,
        workspace: Workspace.create,
        parameter: parameter
      )
      context = Evaluator.context

      allow(@target_matcher).to receive(:matches).and_return(true)

      expect { @sut.matches(request, context, target_rule) }.to raise_error(ArgumentError, 'bucket [320]')
    end

    it 'when user allocated then return true' do
      target_rule = RemoteConfigs.target_rule(bucket_id: 320)
      parameter = RemoteConfigs.parameter(
        id: 42,
        identifier_type: '$id',
        target_rules: [target_rule]
      )
      request = RemoteConfigs.request(
        user: HackleUser.builder.identifier('$id', 'user').build,
        workspace: Workspace.create(
          buckets: [
            Bucket.new(id: 320, seed: 42, slot_size: 10, slots: [])
          ]
        ),
        parameter: parameter
      )
      context = Evaluator.context

      allow(@target_matcher).to receive(:matches).and_return(true)
      allow(@bucketer).to receive(:bucketing).and_return(double)

      expect(@sut.matches(request, context, target_rule)).to be(true)
    end

    it 'when user not allocated then return false' do
      target_rule = RemoteConfigs.target_rule(bucket_id: 320)
      parameter = RemoteConfigs.parameter(
        id: 42,
        identifier_type: '$id',
        target_rules: [target_rule]
      )
      request = RemoteConfigs.request(
        user: HackleUser.builder.identifier('$id', 'user').build,
        workspace: Workspace.create(
          buckets: [
            Bucket.new(id: 320, seed: 42, slot_size: 10, slots: [])
          ]
        ),
        parameter: parameter
      )
      context = Evaluator.context

      allow(@target_matcher).to receive(:matches).and_return(true)
      allow(@bucketer).to receive(:bucketing).and_return(nil)

      expect(@sut.matches(request, context, target_rule)).to be(false)
    end
  end
end

# frozen_string_literal: true

require 'rspec'
require 'models'
require 'hackle/internal/user/hackle_user_resolver'
require 'hackle/remote_config'
require 'hackle/client'

module Hackle
  RSpec.describe Client do

    before do
      @core = double
      allow(@core).to receive(:close).and_return true
      @sut = Client.new(core: @core, user_resolver: HackleUserResolver.new)
    end

    describe 'experiment' do

      it 'when experiment key is invalid then return default variation' do
        user = User.builder.id('user').build

        expect(@sut.variation_detail(nil, user)).to eq(ExperimentDecision.new('A', DecisionReason::INVALID_INPUT, ParameterConfig.empty))
        expect(@sut.variation_detail('42', user)).to eq(ExperimentDecision.new('A', DecisionReason::INVALID_INPUT, ParameterConfig.empty))
        expect(@sut.variation_detail({ 'key' => 42 }, user)).to eq(ExperimentDecision.new('A', DecisionReason::INVALID_INPUT, ParameterConfig.empty))
      end

      it 'when cannot resolve hackle user then return default variation' do
        user = User.builder.build

        actual = @sut.variation_detail(42, user)

        expect(actual).to eq(ExperimentDecision.new('A', DecisionReason::INVALID_INPUT, ParameterConfig.empty))
      end

      it 'when error raised then return default variation' do
        user = User.builder.id('user').build
        allow(@core).to receive(:experiment).and_raise(RuntimeError)

        actual = @sut.variation_detail(42, user)

        expect(actual).to eq(ExperimentDecision.new('A', DecisionReason::EXCEPTION, ParameterConfig.empty))
      end

      it 'decision' do
        user = User.builder.id('user').build
        decision = ExperimentDecision.new('B', DecisionReason::TRAFFIC_ALLOCATED, ParameterConfig.empty)
        allow(@core).to receive(:experiment).and_return(decision)

        actual = @sut.variation_detail(42, user)

        expect(actual).to eq(decision)
      end

      it 'variation' do
        user = User.builder.id('user').build
        decision = ExperimentDecision.new('B', DecisionReason::TRAFFIC_ALLOCATED, ParameterConfig.empty)
        allow(@core).to receive(:experiment).and_return(decision)

        actual = @sut.variation(42, user)

        expect(actual).to eq('B')
      end
    end

    describe 'feature flag' do
      it 'when feature key is invalid then return false' do
        user = User.builder.id('user').build

        expect(@sut.feature_flag_detail(nil, user)).to eq(FeatureFlagDecision.new(false, DecisionReason::INVALID_INPUT, ParameterConfig.empty))
        expect(@sut.feature_flag_detail('42', user)).to eq(FeatureFlagDecision.new(false, DecisionReason::INVALID_INPUT, ParameterConfig.empty))
        expect(@sut.feature_flag_detail({ 'key' => 42 }, user)).to eq(FeatureFlagDecision.new(false, DecisionReason::INVALID_INPUT, ParameterConfig.empty))
      end

      it 'when cannot resolve hackle user then return false' do
        user = User.builder.build

        actual = @sut.feature_flag_detail(42, user)

        expect(actual).to eq(FeatureFlagDecision.new(false, DecisionReason::INVALID_INPUT, ParameterConfig.empty))
      end

      it 'when error raised then return false' do
        user = User.builder.id('user').build
        allow(@core).to receive(:feature_flag).and_raise(RuntimeError)

        actual = @sut.feature_flag_detail(42, user)

        expect(actual).to eq(FeatureFlagDecision.new(false, DecisionReason::EXCEPTION, ParameterConfig.empty))
      end

      it 'decision' do
        user = User.builder.id('user').build
        decision = FeatureFlagDecision.new(true, DecisionReason::DEFAULT_RULE, ParameterConfig.empty)
        allow(@core).to receive(:feature_flag).and_return(decision)

        actual = @sut.feature_flag_detail(42, user)

        expect(actual).to eq(decision)
      end

      it 'is feature on' do
        user = User.builder.id('user').build
        decision = FeatureFlagDecision.new(true, DecisionReason::DEFAULT_RULE, ParameterConfig.empty)
        allow(@core).to receive(:feature_flag).and_return(decision)

        actual = @sut.is_feature_on(42, user)

        expect(actual).to eq(true)
      end
    end

    describe 'track' do
      it 'invalid event' do
        user = User.builder.id('user').build

        allow(@core).to receive(:track).and_return(nil)

        @sut.track('test', user)
        @sut.track(42, user)
        @sut.track(true, user)
        @sut.track(nil, user)
        @sut.track({ 'key' => '42' }, user)
        @sut.track(Event.new(key: 42, value: nil, properties: {}), user)

        expect(@core).to have_received(:track).exactly(0).times
      end

      it 'invalid user' do
        user = User.builder.build
        event = Event.builder('test').build

        allow(@core).to receive(:track).and_return(nil)

        @sut.track(event, user)

        expect(@core).to have_received(:track).exactly(0).times
      end

      it 'track' do
        user = User.builder.id('user').build
        event = Event.builder('test').build

        allow(@core).to receive(:track).and_return(nil)

        @sut.track(event, user)

        expect(@core).to have_received(:track).exactly(1).times
      end

      it 'error' do
        user = User.builder.id('user').build
        event = Event.builder('test').build

        allow(@core).to receive(:track).and_raise(RuntimeError)

        @sut.track(event, user)
      end
    end

    it 'remote_config' do
      user = User.builder.id('user').build

      actual = @sut.remote_config(user)

      expect(actual).to be_a(RemoteConfig)
    end

    it 'close' do
      @sut.close

      expect(@core).to have_received(:close).exactly(1).times
    end
  end
end

# frozen_string_literal: true

require 'rspec'
require 'models'
require 'json'
require 'hackle/internal/workspace/workspace_fetcher'
require 'hackle/internal/event/user_event_processor'
require 'hackle/internal/core/hackle_core'

module Hackle
  RSpec.describe Core do
    before do
      @experiment_evaluator = double
      @remote_config_evaluator = double
      @workspace_fetcher = double
      @event_factory = double
      @event_processor = double
      @clock = FixedClock.new(42)

      allow(@event_processor).to receive(:process).and_return(nil)

      @sut = Core.new(
        experiment_evaluator: @experiment_evaluator,
        remote_config_evaluator: @remote_config_evaluator,
        workspace_fetcher: @workspace_fetcher,
        event_factory: @event_factory,
        event_processor: @event_processor,
        clock: @clock
      )
    end

    it 'close' do
      allow(@workspace_fetcher).to receive(:stop).and_return nil
      allow(@event_processor).to receive(:stop).and_return nil

      @sut.close

      expect(@workspace_fetcher).to have_received(:stop).exactly(1).times
      expect(@event_processor).to have_received(:stop).exactly(1).times
    end

    it 'resume' do
      allow(@workspace_fetcher).to receive(:resume).and_return nil
      allow(@event_processor).to receive(:resume).and_return nil

      @sut.resume

      expect(@workspace_fetcher).to have_received(:resume).exactly(1).times
      expect(@event_processor).to have_received(:resume).exactly(1).times
    end

    describe 'experiment' do
      it 'when sdk not ready then return default variation' do
        user = HackleUser.builder.build
        allow(@workspace_fetcher).to receive(:fetch).and_return(nil)

        actual = @sut.experiment(42, user, 'A')

        expect(actual).to eq(ExperimentDecision.new('A', DecisionReason::SDK_NOT_READY, ParameterConfig.empty))
      end

      it 'when experiment not found then return default variation' do
        user = HackleUser.builder.build
        workspace = Workspace.create
        allow(@workspace_fetcher).to receive(:fetch).and_return(workspace)

        actual = @sut.experiment(42, user, 'A')

        expect(actual).to eq(ExperimentDecision.new('A', DecisionReason::EXPERIMENT_NOT_FOUND, ParameterConfig.empty))
      end

      it 'when experiment evaluated then return evalauted variation with process events' do
        user = HackleUser.builder.build
        experiment = Experiments.create(key: 42)
        workspace = Workspace.create(experiments: [experiment])
        allow(@workspace_fetcher).to receive(:fetch).and_return(workspace)

        evaluation = ExperimentEvaluation.new(
          reason: DecisionReason::TRAFFIC_ALLOCATED,
          target_evaluations: [],
          experiment: experiment,
          variation_id: 320,
          variation_key: 'B',
          config: ParameterConfiguration.new(id: 420, parameters: { 'A' => 'B' })
        )
        allow(@experiment_evaluator).to receive(:evaluate).and_return(evaluation)
        allow(@event_factory).to receive(:create).and_return([double, double])

        actual = @sut.experiment(42, user, 'A')

        expect(actual.variation).to eq('B')
        expect(actual.reason).to eq('TRAFFIC_ALLOCATED')
        expect(actual.get('A')).to eq('B')
        expect(@event_processor).to have_received(:process).exactly(2).times
      end
    end

    describe 'feature flag' do
      it 'when sdk not ready then return default variation' do
        user = HackleUser.builder.build
        allow(@workspace_fetcher).to receive(:fetch).and_return(nil)

        actual = @sut.feature_flag(42, user)

        expect(actual).to eq(FeatureFlagDecision.new(false, DecisionReason::SDK_NOT_READY, ParameterConfig.empty))
      end

      it 'when experiment not found then return default variation' do
        user = HackleUser.builder.build
        workspace = Workspace.create
        allow(@workspace_fetcher).to receive(:fetch).and_return(workspace)

        actual = @sut.feature_flag(42, user)

        expect(actual).to eq(FeatureFlagDecision.new(false, DecisionReason::FEATURE_FLAG_NOT_FOUND,
                                                     ParameterConfig.empty))
      end

      it 'when feature flag evaluated as A then return false' do
        user = HackleUser.builder.build
        experiment = Experiments.create(key: 42, type: ExperimentType::FEATURE_FLAG)
        workspace = Workspace.create(feature_flags: [experiment])
        allow(@workspace_fetcher).to receive(:fetch).and_return(workspace)

        evaluation = ExperimentEvaluation.new(
          reason: DecisionReason::DEFAULT_RULE,
          target_evaluations: [],
          experiment: experiment,
          variation_id: 320,
          variation_key: 'A',
          config: ParameterConfiguration.new(id: 420, parameters: { 'A' => 'B' })
        )
        allow(@experiment_evaluator).to receive(:evaluate).and_return(evaluation)
        allow(@event_factory).to receive(:create).and_return([double, double])

        actual = @sut.feature_flag(42, user)

        expect(actual.is_on).to eq(false)
        expect(actual.reason).to eq('DEFAULT_RULE')
        expect(actual.get('A')).to eq('B')
        expect(@event_processor).to have_received(:process).exactly(2).times
      end

      it 'when feature flag evalauted as not A then return true' do
        user = HackleUser.builder.build
        experiment = Experiments.create(key: 42, type: ExperimentType::FEATURE_FLAG)
        workspace = Workspace.create(feature_flags: [experiment])
        allow(@workspace_fetcher).to receive(:fetch).and_return(workspace)

        evaluation = ExperimentEvaluation.new(
          reason: DecisionReason::DEFAULT_RULE,
          target_evaluations: [],
          experiment: experiment,
          variation_id: 320,
          variation_key: 'B',
          config: ParameterConfiguration.new(id: 420, parameters: { 'A' => 'B' })
        )
        allow(@experiment_evaluator).to receive(:evaluate).and_return(evaluation)
        allow(@event_factory).to receive(:create).and_return([double, double])

        actual = @sut.feature_flag(42, user)

        expect(actual.is_on).to eq(true)
        expect(actual.reason).to eq('DEFAULT_RULE')
        expect(actual.get('A')).to eq('B')
        expect(@event_processor).to have_received(:process).exactly(2).times
      end
    end

    describe 'remote config' do
      it 'when sdk not ready then return default variation' do
        user = HackleUser.builder.build
        allow(@workspace_fetcher).to receive(:fetch).and_return(nil)

        actual = @sut.remote_config('42', user, ValueType::STRING, 'default')

        expect(actual).to eq(RemoteConfigDecision.new('default', DecisionReason::SDK_NOT_READY))
      end

      it 'when rc parameter not found then return default value' do
        user = HackleUser.builder.build
        workspace = Workspace.create
        allow(@workspace_fetcher).to receive(:fetch).and_return(workspace)

        actual = @sut.remote_config('42', user, ValueType::STRING, 'default')

        expect(actual).to eq(RemoteConfigDecision.new('default', DecisionReason::REMOTE_CONFIG_PARAMETER_NOT_FOUND))
      end

      it 'when rc evaluated then return evaluated value with process events' do
        user = HackleUser.builder.build
        parameter = RemoteConfigs.parameter(key: '42')
        workspace = Workspace.create(remote_config_parameters: [parameter])
        allow(@workspace_fetcher).to receive(:fetch).and_return(workspace)

        evaluation = RemoteConfigEvaluation.new(
          reason: DecisionReason::DEFAULT_RULE,
          target_evaluations: [],
          parameter: parameter,
          value_id: 320,
          value: 'evaluated',
          properties: {}
        )
        allow(@remote_config_evaluator).to receive(:evaluate).and_return(evaluation)
        allow(@event_factory).to receive(:create).and_return([double, double])

        actual = @sut.remote_config('42', user, ValueType::STRING, 'default')

        expect(actual).to eq(RemoteConfigDecision.new('evaluated', DecisionReason::DEFAULT_RULE))
        expect(@event_processor).to have_received(:process).exactly(2).times
      end
    end

    describe 'track' do
      it 'when sdk not ready then track with event_id = 0' do
        user = HackleUser.builder.build
        event = Event.builder('42').build

        allow(@workspace_fetcher).to receive(:fetch).and_return(nil)

        @sut.track(event, user)

        expect(@event_processor).to have_received(:process).exactly(1).times
        expect(@event_processor).to have_received(:process) { |it|
          expect(it.event_type.id).to eq(0)
          expect(it.timestamp).to eq(42)
        }
      end

      it 'track' do
        user = HackleUser.builder.build
        event = Event.builder('42').build

        event_type = EventType.new(id: 42, key: '42')
        workspace = Workspace.create(event_types: [event_type])
        allow(@workspace_fetcher).to receive(:fetch).and_return(workspace)

        @sut.track(event, user)

        expect(@event_processor).to have_received(:process).exactly(1).times
        expect(@event_processor).to have_received(:process) { |it|
          expect(it.event_type.id).to eq(42)
          expect(it.timestamp).to eq(42)
        }
      end
    end

    describe 'core' do
      # @param filename [String]
      # @return [Workspace]
      def workspace(filename)
        # json = File.read('spec/data/workspace_target_experiment.json')
        json = File.read(filename)
        hash = JSON.parse(json, symbolize_names: true)
        Workspace.from_hash(hash)
      end

      #
      #      RC(1)
      #     /     \
      #    /       \
      # AB(2)     FF(4)
      #   |   \     |
      #   |     \   |
      # AB(3)     FF(5)
      #             |
      #             |
      #           AB(6)
      #
      it 'target_experiment' do
        workspace_fetcher = FileWorkspaceFetcher.new('spec/data/workspace_target_experiment.json')
        event_processor = MemoryUserEventProcessor.new
        core = Core.create(workspace_fetcher: workspace_fetcher, event_processor: event_processor)

        user = HackleUser.builder.identifier('$id', 'user').build

        actual = core.remote_config('rc', user, ValueType::STRING, '!!')

        expect(actual).to eq(RemoteConfigDecision.new('Targeting!!', DecisionReason::TARGET_RULE_MATCH))

        expect(event_processor.events.length).to eq(6)
        expect(event_processor.events[0].properties).to eq({
                                                             'requestValueType' => 'STRING',
                                                             'requestDefaultValue' => '!!',
                                                             'targetRuleKey' => 'rc_1_key',
                                                             'targetRuleName' => 'rc_1_name',
                                                             'returnValue' => 'Targeting!!'
                                                           })

        event_processor.events.drop(1).each do |event|
          expect(event.properties['$targetingRootType']).to eq('REMOTE_CONFIG')
          expect(event.properties['$targetingRootId']).to eq(1)
        end
      end

      #
      #     RC(1)
      #      ↓
      # ┌── AB(2)
      # ↑    ↓
      # |   FF(3)
      # ↑    ↓
      # |   AB(4)
      # └────┘
      #
      it 'target_experiment_circular' do
        workspace_fetcher = FileWorkspaceFetcher.new('spec/data/workspace_target_experiment_circular.json')
        event_processor = MemoryUserEventProcessor.new
        core = Core.create(workspace_fetcher: workspace_fetcher, event_processor: event_processor)

        user = HackleUser.builder.identifier('$id', 'user').build

        expect { core.remote_config('rc', user, ValueType::STRING, 'XXX') }.to raise_error(ArgumentError, 'circular evaluation has occurred')
      end

      #
      #                     Container(1)
      # ┌──────────────┬───────────────────────────────────────┐
      # | ┌──────────┐ |                                       |
      # | |   AB(2)  | |                                       |
      # | └──────────┘ |                                       |
      # └──────────────┴───────────────────────────────────────┘
      #       25 %                        75 %
      #
      it 'container' do
        workspace_fetcher = FileWorkspaceFetcher.new('spec/data/workspace_container.json')
        event_processor = MemoryUserEventProcessor.new
        core = Core.create(workspace_fetcher: workspace_fetcher, event_processor: event_processor)

        decisions = 10_000.times.map do |i|
          user = HackleUser.builder.identifier('$id', i.to_s).build
          core.experiment(2, user, 'A')
        end

        expect(event_processor.events.length).to eq(10_000)

        expect(decisions.count { |it| it.reason == 'TRAFFIC_ALLOCATED' }).to eq(2452)
      end

      it 'segment_match' do
        workspace_fetcher = FileWorkspaceFetcher.new('spec/data/workspace_segment_match.json')
        event_processor = MemoryUserEventProcessor.new
        core = Core.create(workspace_fetcher: workspace_fetcher, event_processor: event_processor)

        d1 = core.experiment(1, HackleUser.builder.identifier('$id', 'matched_id').build, 'A')
        expect(d1.variation).to eq('A')
        expect(d1.reason).to eq('OVERRIDDEN')

        d2 = core.experiment(1, HackleUser.builder.identifier('$id', 'not_matched_id').build, 'A')
        expect(d2.variation).to eq('A')
        expect(d2.reason).to eq('TRAFFIC_ALLOCATED')
      end
    end
  end

  class FileWorkspaceFetcher
    include WorkspaceFetcher

    def initialize(filename)
      json = File.read(filename)
      hash = JSON.parse(json, symbolize_names: true)
      @workspace = Workspace.from_hash(hash)
    end

    def fetch
      @workspace
    end
  end

  class MemoryUserEventProcessor
    include UserEventProcessor
    attr_reader :events

    def initialize
      @events = []
    end

    def process(event)
      @events << event
    end
  end
end

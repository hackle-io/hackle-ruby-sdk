# frozen_string_literal: true

require 'rspec'
require 'models'
require 'hackle/internal/event/user_event'
require 'hackle/internal/event/user_event_factory'

module Hackle
  RSpec.describe UserEventFactory do
    it 'create' do
      sut = UserEventFactory.new(clock: FixedClock.new(42))

      context = Evaluator.context

      evaluation1 = ExperimentEvaluation.new(
        reason: 'TRAFFIC_ALLOCATED',
        target_evaluations: [],
        experiment: Experiments.create(
          id: 1,
          type: ExperimentType::AB_TEST,
          version: 1,
          execution_version: 1
        ),
        variation_id: 42,
        variation_key: 'B',
        config: ParameterConfiguration.new(id: 42, parameters: {})
      )

      evaluation2 = ExperimentEvaluation.new(
        reason: 'DEFAULT_RULE',
        target_evaluations: [],
        experiment: Experiments.create(
          id: 2,
          type: ExperimentType::FEATURE_FLAG,
          version: 2,
          execution_version: 3
        ),
        variation_id: 320,
        variation_key: 'A',
        config: nil
      )

      context.add_evaluation(evaluation1)
      context.add_evaluation(evaluation2)

      hackle_user = HackleUser.builder.identifier('a', 'b').build

      request = RemoteConfigRequest.create(
        Workspace.create,
        hackle_user,
        RemoteConfigs.parameter(id: 2000),
        ValueType::STRING,
        'default'
      )
      evaluation = RemoteConfigEvaluation.create(
        request,
        context,
        999,
        'RC',
        'TARGET_RULE_MATCH',
        PropertiesBuilder.new
      )

      events = sut.create(request, evaluation)

      expect(events.length).to eq(3)

      expect(events[0]).to be_a(RemoteConfigEvent)
      expect(events[0].timestamp).to eq(42)
      expect(events[0].user).to eq(hackle_user)
      expect(events[0].parameter.id).to eq(2000)
      expect(events[0].value_id).to eq(999)
      expect(events[0].decision_reason).to eq('TARGET_RULE_MATCH')
      expect(events[0].properties).to eq({
                                           'returnValue' => 'RC'
                                         })

      expect(events[1]).to be_a(ExposureEvent)
      expect(events[1].timestamp).to eq(42)
      expect(events[1].user).to eq(hackle_user)
      expect(events[1].experiment.id).to eq(1)
      expect(events[1].variation_id).to eq(42)
      expect(events[1].variation_key).to eq('B')
      expect(events[1].decision_reason).to eq('TRAFFIC_ALLOCATED')
      expect(events[1].properties).to eq({
                                           '$targetingRootType' => 'REMOTE_CONFIG',
                                           '$targetingRootId' => 2000,
                                           '$parameterConfigurationId' => 42,
                                           '$experiment_version' => 1,
                                           '$execution_version' => 1
                                         })

      expect(events[2]).to be_a(ExposureEvent)
      expect(events[2].timestamp).to eq(42)
      expect(events[2].user).to eq(hackle_user)
      expect(events[2].experiment.id).to eq(2)
      expect(events[2].variation_id).to eq(320)
      expect(events[2].variation_key).to eq('A')
      expect(events[2].decision_reason).to eq('DEFAULT_RULE')
      expect(events[2].properties).to eq({
                                           '$targetingRootType' => 'REMOTE_CONFIG',
                                           '$targetingRootId' => 2000,
                                           '$experiment_version' => 2,
                                           '$execution_version' => 3
                                         })
    end

    it 'unsupported' do
      sut = UserEventFactory.new(clock: FixedClock.new(42))

      expect(sut.create(Evaluators.request, Evaluators.evaluation)).to be_empty

      context = Evaluator.context
      context.add_evaluation(Evaluators.evaluation)

      request = RemoteConfigRequest.create(
        Workspace.create,
        HackleUser.builder.identifier('a', 'b').build,
        RemoteConfigs.parameter(id: 2000),
        ValueType::STRING,
        'default'
      )
      evaluation = RemoteConfigEvaluation.create(
        request,
        context,
        999,
        'RC',
        'TARGET_RULE_MATCH',
        PropertiesBuilder.new
      )

      expect(sut.create(request, evaluation).length).to eq(1)
    end
  end
end

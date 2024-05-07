# frozen_string_literal: true

require 'rspec'
require 'models'
require 'hackle/internal/evaluation/evaluator/experiment/experiment_flow_evaluator'

module Hackle

  RSpec.describe ExperimentFlowEvaluator do

    before do
      @next_flow = double
      @evaluation = double
      allow(@next_flow).to receive(:evaluate).and_return(@evaluation)
      @context = Evaluator.context
    end

    describe OverrideExperimentFlowEvaluator do

      before do
        @override_resolver = double
        @sut = OverrideExperimentFlowEvaluator.new(override_resolver: @override_resolver)
      end

      it 'when resolve as nil then evaluate next_flow' do
        request = Experiments.request(experiment: Experiments.create(id: 42, type: ExperimentType::AB_TEST))
        allow(@override_resolver).to receive(:resolve_or_nil).and_return(nil)

        actual = @sut.evaluate(request, @context, @next_flow)

        expect(actual).to be(@evaluation)
      end

      it 'when ab test overridden then return overridden variation with overridden reason' do
        experiment = Experiments.create(id: 42, type: ExperimentType::AB_TEST)
        variation = experiment.variations[0]
        request = Experiments.request(experiment: experiment)
        allow(@override_resolver).to receive(:resolve_or_nil).and_return(variation)

        actual = @sut.evaluate(request, @context, @next_flow)

        expect(actual.variation_id).to be(variation.id)
        expect(actual.reason).to be('OVERRIDDEN')
      end

      it 'when feature flag overridden then return overridden variation with individual match reason' do
        experiment = Experiments.create(id: 42, type: ExperimentType::FEATURE_FLAG)
        variation = experiment.variations[0]
        request = Experiments.request(experiment: experiment)
        allow(@override_resolver).to receive(:resolve_or_nil).and_return(variation)

        actual = @sut.evaluate(request, @context, @next_flow)

        expect(actual.variation_id).to be(variation.id)
        expect(actual.reason).to be('INDIVIDUAL_TARGET_MATCH')
      end

      it 'when unsupported experiment type then raise error' do
        experiment = Experiments.create(id: 42, type: ExperimentType.new('INVALID'))
        variation = experiment.variations[0]
        request = Experiments.request(experiment: experiment)
        allow(@override_resolver).to receive(:resolve_or_nil).and_return(variation)

        expect { @sut.evaluate(request, @context, @next_flow) }.to raise_error(ArgumentError, 'unsupported experiment type [INVALID]')
      end
    end

    describe DraftExperimentFlowEvaluator do
      before do
        @sut = DraftExperimentFlowEvaluator.new
      end

      it 'when draft experiment then return default variation' do
        experiment = Experiments.create(id: 42,
                                        type: ExperimentType::AB_TEST,
                                        status: ExperimentStatus::DRAFT,
                                        variations: [Experiments.variation(id: 42, key: 'A'),
                                                     Experiments.variation(id: 43, key: 'B')]
        )
        request = Experiments.request(experiment: experiment)

        actual = @sut.evaluate(request, @context, @next_flow)

        expect(actual.variation_id).to eq(42)
        expect(actual.reason).to be('EXPERIMENT_DRAFT')
      end

      it 'when not draft experiment then evaluate next flow' do
        experiment = Experiments.create(id: 42,
                                        type: ExperimentType::AB_TEST,
                                        status: ExperimentStatus::RUNNING,
                                        variations: [Experiments.variation(id: 42, key: 'A'),
                                                     Experiments.variation(id: 43, key: 'B')]
        )
        request = Experiments.request(experiment: experiment)

        actual = @sut.evaluate(request, @context, @next_flow)

        expect(actual).to be(@evaluation)
      end
    end

    describe PausedExperimentFlowEvaluator do

      before do
        @sut = PausedExperimentFlowEvaluator.new
      end

      it 'when paused ab test then return default variation' do
        experiment = Experiments.create(
          id: 42,
          type: ExperimentType::AB_TEST,
          status: ExperimentStatus::PAUSED
        )
        request = Experiments.request(experiment: experiment)

        actual = @sut.evaluate(request, @context, @next_flow)

        expect(actual.variation_key).to be('A')
        expect(actual.reason).to be('EXPERIMENT_PAUSED')
      end

      it 'when paused feature flag then return default variation' do
        experiment = Experiments.create(
          id: 42,
          type: ExperimentType::FEATURE_FLAG,
          status: ExperimentStatus::PAUSED
        )
        request = Experiments.request(experiment: experiment)

        actual = @sut.evaluate(request, @context, @next_flow)

        expect(actual.variation_key).to be('A')
        expect(actual.reason).to be('FEATURE_FLAG_INACTIVE')
      end

      it 'when not paused experiment then evaluate next flow' do
        experiment = Experiments.create(
          id: 42,
          type: ExperimentType::AB_TEST,
          status: ExperimentStatus::RUNNING
        )
        request = Experiments.request(experiment: experiment)

        actual = @sut.evaluate(request, @context, @next_flow)

        expect(actual).to be(@evaluation)
      end

      it 'when unsupported experiment type then raise error' do
        experiment = Experiments.create(
          id: 42,
          type: ExperimentType.new('INVALID'),
          status: ExperimentStatus::PAUSED
        )
        request = Experiments.request(experiment: experiment)

        expect { @sut.evaluate(request, @context, @next_flow) }.to raise_error(ArgumentError, 'unsupported experiment type [INVALID]')
      end
    end

    describe CompletedExperimentFlowEvaluator do
      before do
        @sut = CompletedExperimentFlowEvaluator.new
      end

      it 'when not completed experiment then evaluate next flow' do
        experiment = Experiments.create(
          id: 42,
          type: ExperimentType::AB_TEST,
          status: ExperimentStatus::RUNNING,
          variations: [
            Experiments.variation(id: 1001, key: 'A'),
            Experiments.variation(id: 1002, key: 'B')
          ]
        )
        request = Experiments.request(experiment: experiment)

        actual = @sut.evaluate(request, @context, @next_flow)

        expect(actual).to be(@evaluation)
      end

      it 'when completed experiment then return winner variation' do
        experiment = Experiments.create(
          id: 42,
          type: ExperimentType::AB_TEST,
          status: ExperimentStatus::COMPLETED,
          variations: [
            Experiments.variation(id: 1001, key: 'A'),
            Experiments.variation(id: 1002, key: 'B')
          ],
          winner_variation_id: 1002
        )
        request = Experiments.request(experiment: experiment)

        actual = @sut.evaluate(request, @context, @next_flow)

        expect(actual.variation_id).to be(1002)
        expect(actual.reason).to be('EXPERIMENT_COMPLETED')
      end

      it 'when completed experiment without winner then raise error' do
        experiment = Experiments.create(
          id: 42,
          type: ExperimentType::AB_TEST,
          status: ExperimentStatus::COMPLETED,
          variations: [
            Experiments.variation(id: 1001, key: 'A'),
            Experiments.variation(id: 1002, key: 'B')
          ],
          winner_variation_id: nil
        )
        request = Experiments.request(experiment: experiment)

        expect { @sut.evaluate(request, @context, @next_flow) }.to raise_error(ArgumentError, 'winner variation [42]')
      end
    end

    describe TargetExperimentFlowEvaluator do

      before do
        @target_determiner = double
        @sut = TargetExperimentFlowEvaluator.new(target_determiner: @target_determiner)
      end

      it 'when experiment is not ab test type then raise error' do
        experiment = Experiments.create(
          id: 42,
          type: ExperimentType::FEATURE_FLAG
        )
        request = Experiments.request(experiment: experiment)

        expect { @sut.evaluate(request, @context, @next_flow) }.to raise_error(ArgumentError, 'experiment type must be AB_TEST [42]')
      end

      it 'when user in experiment target then evaluate next flow' do
        experiment = Experiments.create(
          id: 42,
          type: ExperimentType::AB_TEST
        )
        request = Experiments.request(experiment: experiment)
        allow(@target_determiner).to receive(:user_in_experiment_target?).and_return(true)

        actual = @sut.evaluate(request, @context, @next_flow)

        expect(actual).to be(@evaluation)
      end

      it 'when user not in experiment target then return default variation' do
        experiment = Experiments.create(
          id: 42,
          type: ExperimentType::AB_TEST,
          variations: [
            Experiments.variation(id: 1001, key: 'A'),
            Experiments.variation(id: 1002, key: 'B')
          ]
        )
        request = Experiments.request(experiment: experiment)
        allow(@target_determiner).to receive(:user_in_experiment_target?).and_return(false)

        actual = @sut.evaluate(request, @context, @next_flow)

        expect(actual.variation_id).to eq(1001)
        expect(actual.reason).to be('NOT_IN_EXPERIMENT_TARGET')
      end
    end

    describe TrafficAllocateExperimentFlowEvaluator do
      before do
        @action_resolver = double
        @sut = TrafficAllocateExperimentFlowEvaluator.new(action_resolver: @action_resolver)
      end

      it 'when experiment is not running then raise error' do
        experiment = Experiments.create(
          id: 42,
          type: ExperimentType::AB_TEST,
          status: ExperimentStatus::DRAFT
        )
        request = Experiments.request(experiment: experiment)

        expect { @sut.evaluate(request, @context, @next_flow) }.to raise_error(ArgumentError, 'experiment status must be RUNNING [42]')
      end

      it 'when experiment is not ab test type then raise error' do
        experiment = Experiments.create(
          id: 42,
          type: ExperimentType::FEATURE_FLAG,
          status: ExperimentStatus::RUNNING
        )
        request = Experiments.request(experiment: experiment)

        expect { @sut.evaluate(request, @context, @next_flow) }.to raise_error(ArgumentError, 'experiment type must be AB_TEST [42]')
      end

      it 'when cannot resolve variation then return default variation' do
        experiment = Experiments.create(
          id: 42,
          type: ExperimentType::AB_TEST,
          status: ExperimentStatus::RUNNING
        )
        request = Experiments.request(experiment: experiment)

        allow(@action_resolver).to receive(:resolve_or_nil).and_return(nil)

        actual = @sut.evaluate(request, @context, @next_flow)

        expect(actual.variation_key).to be('A')
        expect(actual.reason).to be('TRAFFIC_NOT_ALLOCATED')
      end

      it 'when resolved variation is dropped then return default variation' do
        experiment = Experiments.create(
          id: 42,
          type: ExperimentType::AB_TEST,
          status: ExperimentStatus::RUNNING,
          variations: [
            Experiments.variation(id: 1001, key: 'A'),
            Experiments.variation(id: 1002, key: 'B', is_dropped: true)
          ]
        )
        request = Experiments.request(experiment: experiment)

        allow(@action_resolver).to receive(:resolve_or_nil).and_return(Experiments.variation(id: 1002, key: 'B', is_dropped: true))

        actual = @sut.evaluate(request, @context, @next_flow)

        expect(actual.variation_key).to be('A')
        expect(actual.reason).to be('VARIATION_DROPPED')
      end

      it 'when variation decide then return variation' do
        experiment = Experiments.create(
          id: 42,
          type: ExperimentType::AB_TEST,
          status: ExperimentStatus::RUNNING,
          variations: [
            Experiments.variation(id: 1001, key: 'A'),
            Experiments.variation(id: 1002, key: 'B')
          ]
        )
        request = Experiments.request(experiment: experiment)

        allow(@action_resolver).to receive(:resolve_or_nil).and_return(Experiments.variation(id: 1002, key: 'B'))

        actual = @sut.evaluate(request, @context, @next_flow)

        expect(actual.variation_id).to be(1002)
        expect(actual.reason).to be('TRAFFIC_ALLOCATED')
      end
    end

    describe TargetRuleExperimentFlowEvaluator do
      before do
        @target_rule_determiner = double
        @action_resolver = double
        @sut = TargetRuleExperimentFlowEvaluator.new(
          target_rule_determiner: @target_rule_determiner,
          action_resolver: @action_resolver)
      end

      it 'when experiment is not running then raise error' do
        experiment = Experiments.create(
          id: 42,
          type: ExperimentType::FEATURE_FLAG,
          status: ExperimentStatus::DRAFT
        )
        request = Experiments.request(experiment: experiment)

        expect { @sut.evaluate(request, @context, @next_flow) }.to raise_error(ArgumentError, 'experiment status must be RUNNING [42]')
      end

      it 'when experiment is not feature flag type then raise error' do
        experiment = Experiments.create(
          id: 42,
          type: ExperimentType::AB_TEST,
          status: ExperimentStatus::RUNNING
        )
        request = Experiments.request(experiment: experiment)

        expect { @sut.evaluate(request, @context, @next_flow) }.to raise_error(ArgumentError, 'experiment type must be FEATURE_FLAG [42]')
      end

      it 'when identifier not exist then evaluate next flow' do
        experiment = Experiments.create(
          id: 42,
          type: ExperimentType::FEATURE_FLAG,
          status: ExperimentStatus::RUNNING,
          variations: [
            Experiments.variation(id: 1001, key: 'A'),
            Experiments.variation(id: 1002, key: 'B')
          ],
          identifier_type: 'custom_id'
        )
        request = Experiments.request(
          user: HackleUser.builder.identifier('$id', 'user').build,
          experiment: experiment
        )

        actual = @sut.evaluate(request, @context, @next_flow)

        expect(actual).to be(@evaluation)
      end

      it 'when cannot determine then evaluate next flow' do
        experiment = Experiments.create(
          id: 42,
          type: ExperimentType::FEATURE_FLAG,
          status: ExperimentStatus::RUNNING,
          variations: [
            Experiments.variation(id: 1001, key: 'A'),
            Experiments.variation(id: 1002, key: 'B')
          ],
          identifier_type: '$id'
        )
        request = Experiments.request(
          user: HackleUser.builder.identifier('$id', 'user').build,
          experiment: experiment
        )

        allow(@target_rule_determiner).to receive(:determine_target_rule_or_nil).and_return(nil)

        actual = @sut.evaluate(request, @context, @next_flow)

        expect(actual).to be(@evaluation)
      end

      it 'when cannot resolve variation then raise error' do
        experiment = Experiments.create(
          id: 42,
          type: ExperimentType::FEATURE_FLAG,
          status: ExperimentStatus::RUNNING,
          variations: [
            Experiments.variation(id: 1001, key: 'A'),
            Experiments.variation(id: 1002, key: 'B')
          ],
          identifier_type: '$id'
        )
        request = Experiments.request(
          user: HackleUser.builder.identifier('$id', 'user').build,
          experiment: experiment
        )

        target_rule = TargetRule.new(target: double, action: double)
        allow(@target_rule_determiner).to receive(:determine_target_rule_or_nil).and_return(target_rule)
        allow(@action_resolver).to receive(:resolve_or_nil).and_return(nil)

        expect { @sut.evaluate(request, @context, @next_flow) }.to raise_error(ArgumentError, 'feature flag must decide the variation [42]')
      end

      it 'when variation resolved then return resolved variation' do
        experiment = Experiments.create(
          id: 42,
          type: ExperimentType::FEATURE_FLAG,
          status: ExperimentStatus::RUNNING,
          variations: [
            Experiments.variation(id: 1001, key: 'A'),
            Experiments.variation(id: 1002, key: 'B')
          ],
          identifier_type: '$id'
        )
        request = Experiments.request(
          user: HackleUser.builder.identifier('$id', 'user').build,
          experiment: experiment
        )

        target_rule = TargetRule.new(target: double, action: double)
        allow(@target_rule_determiner).to receive(:determine_target_rule_or_nil).and_return(target_rule)
        allow(@action_resolver).to receive(:resolve_or_nil).and_return(Experiments.variation(id: 1002, key: 'B'))

        actual = @sut.evaluate(request, @context, @next_flow)

        expect(actual.variation_id).to be(1002)
        expect(actual.reason).to be('TARGET_RULE_MATCH')
      end
    end

    describe DefaultRuleExperimentFlowEvaluator do

      before do
        @action_resolver = double
        @sut = DefaultRuleExperimentFlowEvaluator.new(action_resolver: @action_resolver)
      end

      it 'when experiment is not running then raise error' do
        experiment = Experiments.create(
          id: 42,
          type: ExperimentType::FEATURE_FLAG,
          status: ExperimentStatus::DRAFT
        )
        request = Experiments.request(experiment: experiment)

        expect { @sut.evaluate(request, @context, @next_flow) }.to raise_error(ArgumentError, 'experiment status must be RUNNING [42]')
      end

      it 'when experiment is not feature flag type then raise error' do
        experiment = Experiments.create(
          id: 42,
          type: ExperimentType::AB_TEST,
          status: ExperimentStatus::RUNNING
        )
        request = Experiments.request(experiment: experiment)

        expect { @sut.evaluate(request, @context, @next_flow) }.to raise_error(ArgumentError, 'experiment type must be FEATURE_FLAG [42]')
      end

      it 'when identifier not found then return default variation' do
        experiment = Experiments.create(
          id: 42,
          type: ExperimentType::FEATURE_FLAG,
          status: ExperimentStatus::RUNNING,
          variations: [
            Experiments.variation(id: 1001, key: 'A'),
            Experiments.variation(id: 1002, key: 'B')
          ],
          identifier_type: 'custom_id'
        )
        request = Experiments.request(
          user: HackleUser.builder.identifier('$id', 'user').build,
          experiment: experiment
        )

        actual = @sut.evaluate(request, @context, @next_flow)

        expect(actual.variation_id).to be(1001)
        expect(actual.reason).to be('DEFAULT_RULE')
      end

      it 'when cannot resolve variation then return error' do
        experiment = Experiments.create(
          id: 42,
          type: ExperimentType::FEATURE_FLAG,
          status: ExperimentStatus::RUNNING,
          variations: [
            Experiments.variation(id: 1001, key: 'A'),
            Experiments.variation(id: 1002, key: 'B')
          ],
          identifier_type: '$id'
        )
        request = Experiments.request(
          user: HackleUser.builder.identifier('$id', 'user').build,
          experiment: experiment
        )

        allow(@action_resolver).to receive(:resolve_or_nil).and_return(nil)

        expect { @sut.evaluate(request, @context, @next_flow) }.to raise_error(ArgumentError, 'feature flag must decide the variation [42]')
      end
      it 'when variation decided then return thar variation' do
        experiment = Experiments.create(
          id: 42,
          type: ExperimentType::FEATURE_FLAG,
          status: ExperimentStatus::RUNNING,
          variations: [
            Experiments.variation(id: 1001, key: 'A'),
            Experiments.variation(id: 1002, key: 'B')
          ],
          identifier_type: '$id'
        )
        request = Experiments.request(
          user: HackleUser.builder.identifier('$id', 'user').build,
          experiment: experiment
        )

        allow(@action_resolver).to receive(:resolve_or_nil).and_return(Experiments.variation(id: 1002, key: 'B'))

        actual = @sut.evaluate(request, @context, @next_flow)

        expect(actual.variation_id).to be(1002)
        expect(actual.reason).to be('DEFAULT_RULE')
      end
    end
    describe ContainerExperimentFlowEvaluator do
      before do
        @container_resolver = double
        @sut = ContainerExperimentFlowEvaluator.new(container_resolver: @container_resolver)
      end

      it 'when not mutually exclusion experiment then evaluate next flow' do
        experiment = Experiments.create(
          id: 42,
          type: ExperimentType::FEATURE_FLAG,
          status: ExperimentStatus::RUNNING,
          variations: [
            Experiments.variation(id: 1001, key: 'A'),
            Experiments.variation(id: 1002, key: 'B')
          ],
          container_id: nil
        )
        request = Experiments.request(
          user: HackleUser.builder.identifier('$id', 'user').build,
          experiment: experiment
        )

        actual = @sut.evaluate(request, @context, @next_flow)

        expect(actual).to be(@evaluation)
      end

      it 'when container not found then raise error' do
        experiment = Experiments.create(
          id: 42,
          type: ExperimentType::FEATURE_FLAG,
          status: ExperimentStatus::RUNNING,
          variations: [
            Experiments.variation(id: 1001, key: 'A'),
            Experiments.variation(id: 1002, key: 'B')
          ],
          container_id: 320
        )
        request = Experiments.request(
          workspace: Workspace.create,
          user: HackleUser.builder.identifier('$id', 'user').build,
          experiment: experiment
        )

        expect { @sut.evaluate(request, @context, @next_flow) }.to raise_error(ArgumentError, 'container [320]')
      end

      it 'when user is in container group then evaluate next flow' do
        container = Container.new(id: 320, bucket_id: 420, groups: [])
        experiment = Experiments.create(
          id: 42,
          type: ExperimentType::FEATURE_FLAG,
          status: ExperimentStatus::RUNNING,
          variations: [
            Experiments.variation(id: 1001, key: 'A'),
            Experiments.variation(id: 1002, key: 'B')
          ],
          container_id: 320
        )
        request = Experiments.request(
          workspace: Workspace.create(containers: [container]),
          user: HackleUser.builder.identifier('$id', 'user').build,
          experiment: experiment
        )
        allow(@container_resolver).to receive(:user_in_container_group?).and_return(true)

        actual = @sut.evaluate(request, @context, @next_flow)

        expect(actual).to be(@evaluation)
      end

      it 'when user is not in container group then return defalut variation' do
        container = Container.new(id: 320, bucket_id: 420, groups: [])
        experiment = Experiments.create(
          id: 42,
          type: ExperimentType::FEATURE_FLAG,
          status: ExperimentStatus::RUNNING,
          variations: [
            Experiments.variation(id: 1001, key: 'A'),
            Experiments.variation(id: 1002, key: 'B')
          ],
          container_id: 320
        )
        request = Experiments.request(
          workspace: Workspace.create(containers: [container]),
          user: HackleUser.builder.identifier('$id', 'user').build,
          experiment: experiment
        )
        allow(@container_resolver).to receive(:user_in_container_group?).and_return(false)

        actual = @sut.evaluate(request, @context, @next_flow)

        expect(actual.variation_key).to be('A')
        expect(actual.reason).to be('NOT_IN_MUTUAL_EXCLUSION_EXPERIMENT')
      end
    end

    describe IdentifierExperimentFlowEvaluator do

      before do
        @sut = IdentifierExperimentFlowEvaluator.new
      end

      it 'when identifier not found then return default variation' do
        experiment = Experiments.create(
          id: 42,
          type: ExperimentType::AB_TEST,
          status: ExperimentStatus::RUNNING,
          variations: [
            Experiments.variation(id: 1001, key: 'A'),
            Experiments.variation(id: 1002, key: 'B')
          ],
          identifier_type: 'custom_id'
        )
        request = Experiments.request(
          user: HackleUser.builder.identifier('$id', 'user').build,
          experiment: experiment
        )

        actual = @sut.evaluate(request, @context, @next_flow)

        expect(actual.variation_key).to be('A')
        expect(actual.reason).to be('IDENTIFIER_NOT_FOUND')
      end

      it 'when identifier exist then evaluate next flow' do
        experiment = Experiments.create(
          id: 42,
          type: ExperimentType::AB_TEST,
          status: ExperimentStatus::RUNNING,
          variations: [
            Experiments.variation(id: 1001, key: 'A'),
            Experiments.variation(id: 1002, key: 'B')
          ],
          identifier_type: '$id'
        )
        request = Experiments.request(
          user: HackleUser.builder.identifier('$id', 'user').build,
          experiment: experiment
        )

        actual = @sut.evaluate(request, @context, @next_flow)

        expect(actual).to be(@evaluation)
      end
    end
  end
end

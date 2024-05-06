# frozen_string_literal: true

require 'rspec'
require 'models'
require 'hackle/internal/evaluation/match/condition/experiment/experiment_evaluator_matcher'

module Hackle
  describe ExperimentEvaluatorMatcher do
    describe AbTestEvaluatorMatcher do
      before do
        @evaluator = double
        @value_operator_matcher = double
        @sut = AbTestEvaluatorMatcher.new(
          evaluator: @evaluator,
          value_operator_matcher: @value_operator_matcher
        )
      end

      it 'when key is not integer then raise error' do
        experiment = Experiments.create(
          key: 42,
          type: ExperimentType::AB_TEST
        )
        request = Experiments.request(
          experiment: experiment
        )
        condition = TargetCondition.new(
          key: TargetKey.new(type: TargetKeyType::AB_TEST, name: 'string'),
          match: TargetMatch.new(
            type: TargetMatchType::MATCH,
            operator: TargetOperator::IN,
            value_type: ValueType::STRING,
            values: []
          )
        )

        expect { @sut.matches(request, Evaluator.context, condition) }.to raise_error(ArgumentError)
      end

      it 'when experiment not found then return false' do
        experiment = Experiments.create(
          key: 42,
          type: ExperimentType::AB_TEST
        )
        request = Experiments.request(
          workspace: Workspace.create,
          experiment: experiment
        )
        condition = TargetCondition.new(
          key: TargetKey.new(type: TargetKeyType::AB_TEST, name: '42'),
          match: TargetMatch.new(
            type: TargetMatchType::MATCH,
            operator: TargetOperator::IN,
            value_type: ValueType::STRING,
            values: []
          )
        )

        expect(@sut.matches(request, Evaluator.context, condition)).to eq(false)
      end

      it 'when target evaluated evaluation is not experiment evaluation type then raise error' do
        experiment = Experiments.create(
          key: 42,
          type: ExperimentType::AB_TEST
        )
        request = Experiments.request(
          workspace: Workspace.create(experiments: [experiment]),
          experiment: experiment
        )
        context = Evaluator.context
        condition = TargetCondition.new(
          key: TargetKey.new(type: TargetKeyType::AB_TEST, name: '42'),
          match: TargetMatch.new(
            type: TargetMatchType::MATCH,
            operator: TargetOperator::IN,
            value_type: ValueType::STRING,
            values: []
          )
        )
        evaluation = Evaluators.evaluation
        allow(@evaluator).to receive(:evaluate).and_return(evaluation)

        expect { @sut.matches(request, context, condition) }.to raise_error(ArgumentError)
      end

      it 'when not experiment request then use evaluated evaluation directly' do
        experiment = Experiments.create(
          key: 42,
          type: ExperimentType::AB_TEST
        )
        request = Experiments.request(
          workspace: Workspace.create(experiments: [experiment]),
          experiment: experiment
        )
        context = Evaluator.context
        condition = TargetCondition.new(
          key: TargetKey.new(type: TargetKeyType::AB_TEST, name: '42'),
          match: TargetMatch.new(
            type: TargetMatchType::MATCH,
            operator: TargetOperator::IN,
            value_type: ValueType::STRING,
            values: ['A']
          )
        )

        evaluation = ExperimentEvaluation.create_default(request, context, 'reason')
        allow(@evaluator).to receive(:evaluate).and_return(evaluation)

        actual = @sut.matches(request, context, condition)

        expect(actual).to eq(false)
        expect(context.evaluations[0]).to eq(evaluation)
      end

      it 'when target evaluation is not traffic allocated reason then use evaluation directly' do
        experiment = Experiments.create(
          key: 42,
          type: ExperimentType::AB_TEST
        )
        request = Evaluators.request(
          id: 42,
          workspace: Workspace.create(experiments: [experiment]),
          user: HackleUser.builder.identifier('$id', 'user').build
        )
        context = Evaluator.context
        condition = TargetCondition.new(
          key: TargetKey.new(type: TargetKeyType::AB_TEST, name: '42'),
          match: TargetMatch.new(
            type: TargetMatchType::MATCH,
            operator: TargetOperator::IN,
            value_type: ValueType::STRING,
            values: ['A']
          )
        )
        evaluation = ExperimentEvaluation.new(
          reason: 'reason',
          target_evaluations: [],
          experiment: experiment,
          variation_id: 1,
          variation_key: 'A',
          config: nil
        )
        allow(@evaluator).to receive(:evaluate).and_return(evaluation)

        actual = @sut.matches(request, context, condition)

        expect(actual).to eq(false)
        expect(context.evaluations[0]).to eq(evaluation)
      end

      it 'when target evaluation nis traffic allocated reason then replace reason' do
        experiment = Experiments.create(
          key: 42,
          type: ExperimentType::AB_TEST
        )
        request = Experiments.request(
          workspace: Workspace.create(experiments: [experiment]),
          experiment: experiment
        )
        context = Evaluator.context
        condition = TargetCondition.new(
          key: TargetKey.new(type: TargetKeyType::AB_TEST, name: '42'),
          match: TargetMatch.new(
            type: TargetMatchType::MATCH,
            operator: TargetOperator::IN,
            value_type: ValueType::STRING,
            values: ['A']
          )
        )
        evaluation = ExperimentEvaluation.create(request, context, experiment.variations[0], 'TRAFFIC_ALLOCATED')
        allow(@evaluator).to receive(:evaluate).and_return(evaluation)
        allow(@value_operator_matcher).to receive(:matches).and_return(false)

        actual = @sut.matches(request, context, condition)

        expect(actual).to eq(false)
        expect(context.evaluations[0].reason).to eq('TRAFFIC_ALLOCATED_BY_TARGETING')
      end

      it 'when target evaluation is matched reason then match variation' do
        experiment = Experiments.create(
          key: 42,
          type: ExperimentType::AB_TEST
        )
        request = Experiments.request(
          workspace: Workspace.create(experiments: [experiment]),
          experiment: experiment
        )
        context = Evaluator.context
        condition = TargetCondition.new(
          key: TargetKey.new(type: TargetKeyType::AB_TEST, name: '42'),
          match: TargetMatch.new(
            type: TargetMatchType::MATCH,
            operator: TargetOperator::IN,
            value_type: ValueType::STRING,
            values: ['A']
          )
        )
        evaluation = ExperimentEvaluation.create(request, context, experiment.variations[0], 'TRAFFIC_ALLOCATED')
        allow(@evaluator).to receive(:evaluate).and_return(evaluation)
        allow(@value_operator_matcher).to receive(:matches).and_return(true)

        actual = @sut.matches(request, context, condition)

        expect(actual).to eq(true)
      end

      it 'when target evaluation is not matched reason then return false' do
        experiment = Experiments.create(
          key: 42,
          type: ExperimentType::AB_TEST
        )
        request = Experiments.request(
          workspace: Workspace.create(experiments: [experiment]),
          experiment: experiment
        )
        context = Evaluator.context
        condition = TargetCondition.new(
          key: TargetKey.new(type: TargetKeyType::AB_TEST, name: '42'),
          match: TargetMatch.new(
            type: TargetMatchType::MATCH,
            operator: TargetOperator::IN,
            value_type: ValueType::STRING,
            values: ['A']
          )
        )
        evaluation = ExperimentEvaluation.create(request, context, experiment.variations[0], 'EXPERIMENT_DRAFT')
        allow(@evaluator).to receive(:evaluate).and_return(evaluation)
        allow(@value_operator_matcher).to receive(:matches).and_return(true)

        actual = @sut.matches(request, context, condition)

        expect(actual).to eq(false)
      end

      it 'when already evaluated experiment then not evaluate again' do
        experiment = Experiments.create(
          key: 42,
          type: ExperimentType::AB_TEST
        )
        request = Experiments.request(
          workspace: Workspace.create(experiments: [experiment]),
          experiment: experiment
        )
        context = Evaluator.context
        condition = TargetCondition.new(
          key: TargetKey.new(type: TargetKeyType::AB_TEST, name: '42'),
          match: TargetMatch.new(
            type: TargetMatchType::MATCH,
            operator: TargetOperator::IN,
            value_type: ValueType::STRING,
            values: ['A']
          )
        )
        evaluation = ExperimentEvaluation.create(request, context, experiment.variations[1], 'OVERRIDDEN')
        context.add_evaluation(evaluation)
        allow(@evaluator).to receive(:evaluate).and_return(evaluation)
        allow(@value_operator_matcher).to receive(:matches).and_return(true)

        actual = @sut.matches(request, context, condition)

        expect(actual).to eq(true)
        expect(@evaluator).to have_received(:evaluate).exactly(0).times
        expect(@value_operator_matcher).to have_received(:matches).with('B', anything).exactly(1).times
      end
    end

    describe FeatureFlagEvaluatorMatcher do
      before do
        @evaluator = double
        @value_operator_matcher = double
        @sut = FeatureFlagEvaluatorMatcher.new(
          evaluator: @evaluator,
          value_operator_matcher: @value_operator_matcher
        )
      end

      it 'when key is not integer then raise error' do
        experiment = Experiments.create(
          key: 42,
          type: ExperimentType::FEATURE_FLAG
        )
        request = Experiments.request(
          experiment: experiment
        )
        condition = TargetCondition.new(
          key: TargetKey.new(type: TargetKeyType::AB_TEST, name: 'string'),
          match: TargetMatch.new(
            type: TargetMatchType::MATCH,
            operator: TargetOperator::IN,
            value_type: ValueType::BOOLEAN,
            values: [true]
          )
        )

        expect { @sut.matches(request, Evaluator.context, condition) }.to raise_error(ArgumentError)
      end

      it 'when feature flag not found then return false' do
        experiment = Experiments.create(
          key: 42,
          type: ExperimentType::FEATURE_FLAG
        )
        request = Experiments.request(
          workspace: Workspace.create,
          experiment: experiment
        )
        context = Evaluator.context
        condition = TargetCondition.new(
          key: TargetKey.new(type: TargetKeyType::AB_TEST, name: '42'),
          match: TargetMatch.new(
            type: TargetMatchType::MATCH,
            operator: TargetOperator::IN,
            value_type: ValueType::BOOLEAN,
            values: [true]
          )
        )

        actual = @sut.matches(request, context, condition)

        expect(actual).to eq(false)
      end

      it 'off match' do
        experiment = Experiments.create(
          key: 42,
          type: ExperimentType::FEATURE_FLAG
        )
        request = Experiments.request(
          workspace: Workspace.create(feature_flags: [experiment]),
          experiment: experiment
        )
        context = Evaluator.context
        condition = TargetCondition.new(
          key: TargetKey.new(type: TargetKeyType::AB_TEST, name: '42'),
          match: TargetMatch.new(
            type: TargetMatchType::MATCH,
            operator: TargetOperator::IN,
            value_type: ValueType::BOOLEAN,
            values: [false]
          )
        )
        evaluation = ExperimentEvaluation.create(request, context, experiment.variations[0], 'OVERRIDDEN')
        allow(@evaluator).to receive(:evaluate).and_return(evaluation)
        allow(@value_operator_matcher).to receive(:matches).and_return(true)

        actual = @sut.matches(request, context, condition)

        expect(actual).to eq(true)
        expect(@value_operator_matcher).to have_received(:matches).with(false, anything).exactly(1).times
      end

      it 'on match' do
        experiment = Experiments.create(
          key: 42,
          type: ExperimentType::FEATURE_FLAG
        )
        request = Experiments.request(
          workspace: Workspace.create(feature_flags: [experiment]),
          experiment: experiment
        )
        context = Evaluator.context
        condition = TargetCondition.new(
          key: TargetKey.new(type: TargetKeyType::AB_TEST, name: '42'),
          match: TargetMatch.new(
            type: TargetMatchType::MATCH,
            operator: TargetOperator::IN,
            value_type: ValueType::BOOLEAN,
            values: [true]
          )
        )
        evaluation = ExperimentEvaluation.create(request, context, experiment.variations[1], 'OVERRIDDEN')
        allow(@evaluator).to receive(:evaluate).and_return(evaluation)
        allow(@value_operator_matcher).to receive(:matches).and_return(true)

        actual = @sut.matches(request, context, condition)

        expect(actual).to eq(true)
        expect(@value_operator_matcher).to have_received(:matches).with(true, anything).exactly(1).times
      end
    end
  end
end

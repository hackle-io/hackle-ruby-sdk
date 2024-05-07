# frozen_string_literal: true

require 'rspec'
require 'models'
require 'hackle/internal/evaluation/evaluator/experiment/experiment_resolver'

module Hackle
  RSpec.describe ExperimentTargetRuleDeterminer do

    before do
      @target_matcher = double
      @sut = ExperimentTargetRuleDeterminer.new(target_matcher: @target_matcher)
    end

    it 'when target rule is empty then return nil' do
      request = Experiments.request(
        experiment: Experiments.create(target_rules: [])
      )
      context = Evaluator.context

      actual = @sut.determine_target_rule_or_nil(request, context)

      expect(actual).to be_nil
    end

    it 'when target rule matched first then return that target rule' do
      request = Experiments.request(
        experiment: Experiments.create(target_rules: [
          TargetRule.new(target: double, action: Action.new(type: ActionType::BUCKET, variation_id: nil, bucket_id: 1)),
          TargetRule.new(target: double, action: Action.new(type: ActionType::BUCKET, variation_id: nil, bucket_id: 2)),
          TargetRule.new(target: double, action: Action.new(type: ActionType::BUCKET, variation_id: nil, bucket_id: 3)),
          TargetRule.new(target: double, action: Action.new(type: ActionType::BUCKET, variation_id: nil, bucket_id: 4)),
          TargetRule.new(target: double, action: Action.new(type: ActionType::BUCKET, variation_id: nil, bucket_id: 5))
        ])
      )
      context = Evaluator.context
      allow(@target_matcher).to receive(:matches).and_return(false, false, false, true, false)

      actual = @sut.determine_target_rule_or_nil(request, context)

      expect(actual.action.bucket_id).to be(4)
      expect(@target_matcher).to have_received(:matches).exactly(4).times
    end

    it 'when all target rule do not match then return nil' do
      request = Experiments.request(
        experiment: Experiments.create(target_rules: [
          TargetRule.new(target: double, action: Action.new(type: ActionType::BUCKET, variation_id: nil, bucket_id: 1)),
          TargetRule.new(target: double, action: Action.new(type: ActionType::BUCKET, variation_id: nil, bucket_id: 2)),
          TargetRule.new(target: double, action: Action.new(type: ActionType::BUCKET, variation_id: nil, bucket_id: 3)),
          TargetRule.new(target: double, action: Action.new(type: ActionType::BUCKET, variation_id: nil, bucket_id: 4)),
          TargetRule.new(target: double, action: Action.new(type: ActionType::BUCKET, variation_id: nil, bucket_id: 5))
        ])
      )
      context = Evaluator.context
      allow(@target_matcher).to receive(:matches).and_return(false, false, false, false, false)

      actual = @sut.determine_target_rule_or_nil(request, context)

      expect(actual).to be_nil
      expect(@target_matcher).to have_received(:matches).exactly(5).times
    end
  end
end


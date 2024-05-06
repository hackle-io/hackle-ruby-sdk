# frozen_string_literal: true

require 'rspec'
require 'models'
require 'hackle/internal/evaluation/evaluator/experiment/experiment_resolver'

module Hackle
  RSpec.describe ExperimentOverrideResolver do

    before do
      @target_matcher = double
      @action_resolver = double
      @sut = ExperimentOverrideResolver.new(target_matcher: @target_matcher, action_resolver: @action_resolver)
    end

    it 'when identifier not found then return nil' do
      request = Experiments.request(
        user: HackleUser.builder.identifier('$id', 'user').build,
        experiment: Experiments.create(id: 42, identifier_type: 'custom_id')
      )
      context = Evaluator.context

      actual = @sut.resolve_or_nil(request, context)

      expect(actual).to eq(nil)
    end

    it 'when user overridden then return overridden variation' do
      request = Experiments.request(
        user: HackleUser.builder.identifier('$id', 'user').build,
        experiment: Experiments.create(id: 42,
                                       identifier_type: '$id',
                                       variations: [
                                         Experiments.variation(id: 1001, key: 'A'),
                                         Experiments.variation(id: 1002, key: 'B')
                                       ],
                                       user_overrides: { 'user' => 1002 })
      )
      context = Evaluator.context

      actual = @sut.resolve_or_nil(request, context)

      expect(actual.id).to eq(1002)
    end

    it 'when segment overrides is empty then return nil' do
      request = Experiments.request(
        user: HackleUser.builder.identifier('$id', 'user').build,
        experiment: Experiments.create(id: 42,
                                       identifier_type: '$id',
                                       variations: [
                                         Experiments.variation(id: 1001, key: 'A'),
                                         Experiments.variation(id: 1002, key: 'B')
                                       ],
                                       user_overrides: {},
                                       segment_overrides: [])
      )
      context = Evaluator.context

      actual = @sut.resolve_or_nil(request, context)

      expect(actual).to eq(nil)
    end

    it 'when all segment override not matched then return nil' do
      rule = TargetRule.new(target: double, action: double)
      request = Experiments.request(
        user: HackleUser.builder.identifier('$id', 'user').build,
        experiment: Experiments.create(id: 42,
                                       identifier_type: '$id',
                                       variations: [
                                         Experiments.variation(id: 1001, key: 'A'),
                                         Experiments.variation(id: 1002, key: 'B')
                                       ],
                                       user_overrides: {},
                                       segment_overrides: [rule, rule, rule, rule, rule])
      )
      context = Evaluator.context

      allow(@target_matcher).to receive(:matches).and_return(false, false, false, false, false)

      actual = @sut.resolve_or_nil(request, context)

      expect(actual).to eq(nil)
      expect(@target_matcher).to have_received(:matches).exactly(5).times
    end

    it 'when segment overridden then return overridden variation' do
      rule = TargetRule.new(target: double, action: double)
      request = Experiments.request(
        user: HackleUser.builder.identifier('$id', 'user').build,
        experiment: Experiments.create(id: 42,
                                       identifier_type: '$id',
                                       variations: [
                                         Experiments.variation(id: 1001, key: 'A'),
                                         Experiments.variation(id: 1002, key: 'B')
                                       ],
                                       user_overrides: {},
                                       segment_overrides: [rule, rule, rule, rule, rule])
      )
      context = Evaluator.context

      allow(@target_matcher).to receive(:matches).and_return(false, false, false, true, false)
      allow(@action_resolver).to receive(:resolve_or_nil).and_return(Experiments.variation(id: 1002, key: 'B'))

      actual = @sut.resolve_or_nil(request, context)

      expect(actual).not_to be_nil
      expect(@target_matcher).to have_received(:matches).exactly(4).times
    end
  end
end


# frozen_string_literal: true

require 'rspec'

require 'hackle/internal/evaluation/match/condition/segment/segment_condition_matcher'
require 'hackle/internal/evaluation/evaluator/evaluator'
require 'hackle/internal/model/target'
require 'hackle/internal/model/value_type'
require 'hackle/internal/model/segment'
require 'hackle/internal/workspace/workspace'

module Hackle
  describe SegmentConditionMatcher do
    before do
      @segment_matcher = double
      @sut = SegmentConditionMatcher.new(segment_matcher: @segment_matcher)
    end

    it 'when not segment key type then raise error' do
      request = Evaluators.request
      context = Evaluator.context
      condition = TargetCondition.new(
        key: TargetKey.new(type: TargetKeyType::USER_PROPERTY, name: 'age'),
        match: TargetMatch.new(type: TargetMatchType::MATCH,
                               operator: TargetOperator::IN,
                               value_type: ValueType::STRING,
                               values: ['42'])
      )

      expect { @sut.matches(request, context, condition) }.to raise_error(ArgumentError)
    end

    it 'when match value is empty then return false' do
      request = Evaluators.request
      context = Evaluator.context
      condition = TargetCondition.new(
        key: TargetKey.new(type: TargetKeyType::SEGMENT, name: 'SEGMENT'),
        match: TargetMatch.new(type: TargetMatchType::MATCH,
                               operator: TargetOperator::IN,
                               value_type: ValueType::STRING,
                               values: [])
      )

      actual = @sut.matches(request, context, condition)

      expect(actual).to eq(false)
    end

    it 'when segment key is not string type then raise error' do
      request = Evaluators.request
      context = Evaluator.context
      condition = TargetCondition.new(
        key: TargetKey.new(type: TargetKeyType::SEGMENT, name: 'SEGMENT'),
        match: TargetMatch.new(type: TargetMatchType::MATCH,
                               operator: TargetOperator::IN,
                               value_type: ValueType::STRING,
                               values: [42])
      )

      expect { @sut.matches(request, context, condition) }.to raise_error(ArgumentError, 'segment key [42]')
    end

    it 'when segment not found then return error' do
      request = Evaluators.request
      context = Evaluator.context
      condition = TargetCondition.new(
        key: TargetKey.new(type: TargetKeyType::SEGMENT, name: 'SEGMENT'),
        match: TargetMatch.new(type: TargetMatchType::MATCH,
                               operator: TargetOperator::IN,
                               value_type: ValueType::STRING,
                               values: ['seg_key'])
      )

      expect { @sut.matches(request, context, condition) }.to raise_error(ArgumentError, 'segment [seg_key]')
    end

    it 'when segment matched then return true' do
      workspace = Workspace.create(segments: [Segment.new(id: 42, key: 'seg_key', type: SegmentType::USER_PROPERTY, targets: [])])
      request = Evaluators.request(workspace: workspace)
      context = Evaluator.context
      condition = TargetCondition.new(
        key: TargetKey.new(type: TargetKeyType::SEGMENT, name: 'SEGMENT'),
        match: TargetMatch.new(type: TargetMatchType::MATCH,
                               operator: TargetOperator::IN,
                               value_type: ValueType::STRING,
                               values: ['seg_key'])
      )

      allow(@segment_matcher).to receive(:matches).and_return(true)

      actual = @sut.matches(request, context, condition)

      expect(actual).to eq(true)
    end

    it 'NOT_MATCH' do
      workspace = Workspace.create(segments: [Segment.new(id: 42, key: 'seg_key', type: SegmentType::USER_PROPERTY, targets: [])])
      request = Evaluators.request(workspace: workspace)
      context = Evaluator.context
      condition = TargetCondition.new(
        key: TargetKey.new(type: TargetKeyType::SEGMENT, name: 'SEGMENT'),
        match: TargetMatch.new(type: TargetMatchType::NOT_MATCH,
                               operator: TargetOperator::IN,
                               value_type: ValueType::STRING,
                               values: ['seg_key'])
      )

      allow(@segment_matcher).to receive(:matches).and_return(true)

      actual = @sut.matches(request, context, condition)

      expect(actual).to eq(false)
    end
  end

  describe SegmentMatcher do

    before do
      @user_condition_matcher = double
      @sut = SegmentMatcher.new(user_condition_matcher: @user_condition_matcher)
    end

    def segment(ttt)
      targets = []
      ttt.each do |tt|
        conditions = []
        tt.each_with_index do |t, i|
          condition = TargetCondition.new(key: TargetKey.new(type: TargetKeyType::USER_PROPERTY, name: i.to_s), match: double)
          conditions << condition
          allow(@user_condition_matcher).to receive(:matches).with(anything, anything, condition).and_return(t)
        end
        target = Target.new(conditions: conditions)
        targets << target
      end
      Segment.new(id: 42, key: 'sef', type: SegmentType::USER_PROPERTY, targets: targets)
    end

    it 'when target is empty then return false' do
      request = Evaluators.request
      context = Evaluator.context
      segment = segment([])

      actual = @sut.matches(request, context, segment)

      expect(actual).to eq(false)
    end

    it 'when any if target matched then return true' do
      request = Evaluators.request
      context = Evaluator.context
      segment = segment([
                          [true, true, true, false], # false
                          [false], # false
                          [true, true] # true
                        ])

      actual = @sut.matches(request, context, segment)

      expect(actual).to eq(true)
      expect(@user_condition_matcher).to have_received(:matches).exactly(7).times
    end

    it 'when all target do not matched then return false' do
      request = Evaluators.request
      context = Evaluator.context
      segment = segment([
                          [true, true, true, false], # false
                          [false], # false
                          [false, true] # true
                        ])

      actual = @sut.matches(request, context, segment)

      expect(actual).to eq(false)
      expect(@user_condition_matcher).to have_received(:matches).exactly(6).times
    end
  end
end

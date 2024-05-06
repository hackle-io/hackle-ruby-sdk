# frozen_string_literal: true

require 'rspec'
require 'hackle/internal/evaluation/evaluator/experiment/experiment_resolver'
require 'models'

module Hackle
  describe ExperimentActionResolver do
    before do
      @bucketer = double
      @sut = ExperimentActionResolver.new(bucketer: @bucketer)
    end

    it 'when unsupported type then raise error' do
      request = Experiments.request
      action = Action.new(type: ActionType.new('INVALID'), variation_id: nil, bucket_id: nil)

      expect { @sut.resolve_or_nil(request, action) }.to raise_error(ArgumentError, 'unsupported ActionType [INVALID]')
    end

    describe 'variation' do
      it 'when variation id is nil then raise error' do
        request = Experiments.request(experiment: Experiments.create(id: 42))
        action = Action.new(type: ActionType::VARIATION, variation_id: nil, bucket_id: nil)

        expect { @sut.resolve_or_nil(request, action) }.to raise_error(ArgumentError, 'action variation [42]')
      end

      it 'when cannot found variation then raise error' do
        request = Experiments.request(experiment: Experiments.create(id: 42,
                                                                     variations: [
                                                                       Experiments.variation(id: 1001, key: 'A'),
                                                                       Experiments.variation(id: 1002, key: 'B'),
                                                                     ]))
        action = Action.new(type: ActionType::VARIATION, variation_id: 1000, bucket_id: nil)

        expect { @sut.resolve_or_nil(request, action) }.to raise_error(ArgumentError, 'variation [1000]')
      end

      it 'when variation resolved then return variation' do
        request = Experiments.request(experiment: Experiments.create(id: 42,
                                                                     variations: [
                                                                       Experiments.variation(id: 1001, key: 'A'),
                                                                       Experiments.variation(id: 1002, key: 'B')
                                                                     ]))
        action = Action.new(type: ActionType::VARIATION, variation_id: 1001, bucket_id: nil)

        actual = @sut.resolve_or_nil(request, action)
        expect(actual.id).to eq(1001)
      end
    end

    describe 'bucket' do
      it 'when bucket id is nil then raise error' do
        request = Experiments.request(experiment: Experiments.create(id: 42))
        action = Action.new(type: ActionType::BUCKET, variation_id: nil, bucket_id: nil)

        expect { @sut.resolve_or_nil(request, action) }.to raise_error(ArgumentError, 'action bucket [42]')
      end

      it 'when cannot found bucket then raise error' do
        request = Experiments.request(workspace: Workspace.create, experiment: Experiments.create(id: 42))
        action = Action.new(type: ActionType::BUCKET, variation_id: nil, bucket_id: 2000)

        expect { @sut.resolve_or_nil(request, action) }.to raise_error(ArgumentError, 'bucket [2000]')
      end

      it 'when identifier not found then return nil' do
        request = Experiments.request(
          workspace: Workspace.create(buckets: [Bucket.new(id: 2000, seed: 1, slot_size: 10_000, slots: [])]),
          user: HackleUser.builder.identifier('$id', 'user').build,
          experiment: Experiments.create(id: 42, identifier_type: 'custom_id')
        )
        action = Action.new(type: ActionType::BUCKET, variation_id: nil, bucket_id: 2000)

        actual = @sut.resolve_or_nil(request, action)

        expect(actual).to be_nil
      end

      it 'when not allocated then return nil' do
        request = Experiments.request(
          workspace: Workspace.create(buckets: [Bucket.new(id: 2000, seed: 1, slot_size: 10_000, slots: [])]),
          user: HackleUser.builder.identifier('$id', 'user').build,
          experiment: Experiments.create(id: 42, identifier_type: '$id')
        )
        action = Action.new(type: ActionType::BUCKET, variation_id: nil, bucket_id: 2000)
        allow(@bucketer).to receive(:bucketing).with(anything, anything).and_return(nil)

        actual = @sut.resolve_or_nil(request, action)

        expect(actual).to be_nil
      end

      it 'when allocated then return allocated variation' do
        request = Experiments.request(
          workspace: Workspace.create(buckets: [Bucket.new(id: 2000, seed: 1, slot_size: 10_000, slots: [])]),
          user: HackleUser.builder.identifier('$id', 'user').build,
          experiment: Experiments.create(id: 42,
                                         identifier_type: '$id',
                                         variations: [
                                           Experiments.variation(id: 1001, key: 'A'),
                                           Experiments.variation(id: 1002, key: 'B')
                                         ]
          )
        )
        action = Action.new(type: ActionType::BUCKET, variation_id: nil, bucket_id: 2000)
        allow(@bucketer).to receive(:bucketing).with(anything, anything).and_return(Slot.new(start_inclusive: 0, end_exclusive: 1000, variation_id: 1002))

        actual = @sut.resolve_or_nil(request, action)

        expect(actual.id).to eq(1002)
      end
    end
  end
end

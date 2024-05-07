# frozen_string_literal: true

require 'rspec'
require 'models'
require 'hackle/internal/evaluation/evaluator/experiment/experiment_resolver'

module Hackle
  RSpec.describe ExperimentContainerResolver do
    before do
      @bucketer = double
      @sut = ExperimentContainerResolver.new(bucketer: @bucketer)
    end

    it 'when identifier not found then return false' do
      request = Experiments.request(
        workspace: Workspace.create,
        user: HackleUser.builder.identifier('$id', 'user').build,
        experiment: Experiments.create(id: 42,
                                       identifier_type: 'custom_id')
      )
      container = Container.new(id: 320,
                                bucket_id: 1001,
                                groups: [])

      expect(@sut.user_in_container_group?(request, container)).to eq(false)
    end

    it 'when cannot found bucket then raise error' do
      request = Experiments.request(
        workspace: Workspace.create,
        user: HackleUser.builder.identifier('$id', 'user').build,
        experiment: Experiments.create(id: 42,
                                       identifier_type: '$id')
      )
      container = Container.new(id: 320,
                                bucket_id: 1001,
                                groups: [])
      expect { @sut.user_in_container_group?(request, container) }.to raise_error(ArgumentError, 'bucket [1001]')
    end

    it 'when bucket not allocated then return false' do
      request = Experiments.request(
        workspace: Workspace.create(buckets: [Bucket.new(id: 1001, seed: 42, slot_size: 10_000, slots: [])]),
        user: HackleUser.builder.identifier('$id', 'user').build,
        experiment: Experiments.create(id: 42,
                                       identifier_type: '$id')
      )
      container = Container.new(id: 320,
                                bucket_id: 1001,
                                groups: [])
      allow(@bucketer).to receive(:bucketing).and_return(nil)

      expect(@sut.user_in_container_group?(request, container)).to eq(false)
    end

    it 'when container group not found then raise error' do
      slot = Slot.new(start_inclusive: 0, end_exclusive: 1000, variation_id: 2001)
      request = Experiments.request(
        workspace: Workspace.create(buckets: [Bucket.new(id: 1001, seed: 42, slot_size: 10_000, slots: [slot])]),
        user: HackleUser.builder.identifier('$id', 'user').build,
        experiment: Experiments.create(id: 42,
                                       identifier_type: '$id')
      )
      container = Container.new(id: 320,
                                bucket_id: 1001,
                                groups: [])

      allow(@bucketer).to receive(:bucketing).and_return(slot)

      expect { @sut.user_in_container_group?(request, container) }.to raise_error(ArgumentError, 'container group [2001]')
    end

    it 'when user not in container group then return false' do
      slot = Slot.new(start_inclusive: 0, end_exclusive: 1000, variation_id: 2001)
      request = Experiments.request(
        workspace: Workspace.create(buckets: [Bucket.new(id: 1001, seed: 42, slot_size: 10_000, slots: [slot])]),
        user: HackleUser.builder.identifier('$id', 'user').build,
        experiment: Experiments.create(id: 42,
                                       identifier_type: '$id')
      )
      container = Container.new(id: 320,
                                bucket_id: 1001,
                                groups: [ContainerGroup.new(id: 2001, experiments: [1, 2, 3])])

      allow(@bucketer).to receive(:bucketing).and_return(slot)

      expect(@sut.user_in_container_group?(request, container)).to eq(false)
    end

    it 'when user in container group then return true' do
      slot = Slot.new(start_inclusive: 0, end_exclusive: 1000, variation_id: 2001)
      request = Experiments.request(
        workspace: Workspace.create(buckets: [Bucket.new(id: 1001, seed: 42, slot_size: 10_000, slots: [slot])]),
        user: HackleUser.builder.identifier('$id', 'user').build,
        experiment: Experiments.create(id: 42,
                                       identifier_type: '$id')
      )
      container = Container.new(id: 320,
                                bucket_id: 1001,
                                groups: [ContainerGroup.new(id: 2001, experiments: [1, 2, 3, 42])])

      allow(@bucketer).to receive(:bucketing).and_return(slot)

      expect(@sut.user_in_container_group?(request, container)).to eq(true)
    end
  end
end

# frozen_string_literal: true

module Hackle

  class Container
    # @!attribute [r] id
    #   @return [Integer]
    # @!attribute [r] bucket_id
    #   @return [Integer]
    # @!attribute [r] groups
    #   @return [Array<ContainerGroup>]
    attr_reader :id, :bucket_id, :groups

    # @param id [Integer]
    # @param bucket_id [Integer]
    # @param groups [Array<ContainerGroup>]
    def initialize(id:, bucket_id:, groups:)
      @id = id
      @bucket_id = bucket_id
      @groups = groups
    end

    # @param group_id [Integer]
    # @return [ContainerGroup, nil]
    def get_group_or_nil(group_id)
      groups.each do |group|
        return group if group.id == group_id
      end
      nil
    end
  end

  class ContainerGroup
    # @!attribute [r] id
    #   @return [Integer]
    # @!attribute [r] experiments
    #   @return [Array<Integer>]
    attr_reader :id, :experiments

    # @param id [Integer]
    # @param experiments [Array<Integer>]
    def initialize(id:, experiments:)
      @id = id
      @experiments = experiments
    end
  end
end

# frozen_string_literal: true

module Hackle
  class Segment

    # @!attribute [r] id
    #   @return [Integer]
    # @!attribute [r] key
    #   @return [String]
    # @!attribute [r] type
    #   @return [SegmentType]
    # @!attribute [r] targets
    #   @return [Array<Target>]
    attr_accessor :id, :key, :type, :targets

    # @param id [Integer]
    # @param key [String]
    # @param type [SegmentType]
    # @param targets [Array<Target>]
    def initialize(id:, key:, type:, targets:)
      @id = id
      @key = key
      @type = type
      @targets = targets
    end
  end

  class SegmentType
    # @!attribute [r] name
    #   @return [String]
    attr_reader :name

    # @param name [String]
    def initialize(name)
      @name = name
    end

    def to_s
      name
    end

    USER_ID = new('USER_ID')
    USER_PROPERTY = new('USER_PROPERTY')

    @types = {
      'USER_ID' => USER_ID,
      'USER_PROPERTY' => USER_PROPERTY
    }.freeze

    # @param name [String]
    # @return [SegmentType, nil]
    def self.from_or_nil(name)
      @types[name.upcase]
    end

    # @return [Array<SegmentType>]
    def self.values
      @types.values
    end
  end
end

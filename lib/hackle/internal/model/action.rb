# frozen_string_literal: true

module Hackle
  class Action

    # @!attribute [r] type
    #   @return [ActionType]
    # @!attribute [r] variation_id
    #   @return [Integer, nil]
    # @!attribute [r] bucket_id
    #   @return [Integer, nil]
    attr_reader :type, :variation_id, :bucket_id

    # @param type [ActionType]
    # @param variation_id [Integer, nil]
    # @param bucket_id [Integer, nil]
    def initialize(type:, variation_id: nil, bucket_id: nil)
      @type = type
      @variation_id = variation_id
      @bucket_id = bucket_id
    end
  end

  class ActionType
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

    VARIATION = new('VARIATION')
    BUCKET = new('BUCKET')

    @types = {
      'VARIATION' => VARIATION,
      'BUCKET' => BUCKET
    }.freeze

    # @param name [String]
    # @return [ActionType, nil]
    def self.from_or_nil(name)
      @types[name.upcase]
    end

    # @return [Array<ActionType>]
    def self.values
      @types.values
    end
  end
end

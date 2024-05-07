# frozen_string_literal: true

module Hackle

  class RemoteConfigParameter
    # @!attribute [r] id
    #   @return [Integer]
    # @!attribute [r] key
    #   @return [String]
    # @!attribute [r] type
    #   @return [ValueType]
    # @!attribute [r] identifier_type
    #   @return [String]
    # @!attribute [r] target_rules
    #   @return [Array<RemoteConfigTargetRule>]
    # @!attribute [r] default_value
    #   @return [RemoteConfigValue]
    attr_accessor :id, :key, :type, :identifier_type, :target_rules, :default_value

    # @param id [Integer]
    # @param key [String]
    # @param type [ValueType]
    # @param identifier_type [String]
    # @param target_rules [Array<RemoteConfigTargetRule>]
    # @param default_value [RemoteConfigValue]
    def initialize(id:, key:, type:, identifier_type:, target_rules:, default_value:)
      @id = id
      @key = key
      @type = type
      @identifier_type = identifier_type
      @target_rules = target_rules
      @default_value = default_value
    end
  end

  class RemoteConfigTargetRule
    # @!attribute [r] key
    #   @return [String]
    # @!attribute [r] name
    #   @return [String]
    # @!attribute [r] target
    #   @return [Target]
    # @!attribute [r] bucket_id
    #   @return [Integer]
    # @!attribute [r] value
    #   @return [RemoteConfigValue]
    attr_reader :key, :name, :target, :bucket_id, :value

    # @param key [String]
    # @param name [String]
    # @param target [Target]
    # @param bucket_id [Integer]
    # @param value [RemoteConfigValue]
    def initialize(key:, name:, target:, bucket_id:, value:)
      @key = key
      @name = name
      @target = target
      @bucket_id = bucket_id
      @value = value

    end
  end

  class RemoteConfigValue
    # @!attribute [r] id
    #   @return [Integer]
    # @!attribute [r] raw_value
    #   @return [Object]
    attr_accessor :id, :raw_value

    def initialize(id:, raw_value:)
      @id = id
      @raw_value = raw_value
    end
  end
end

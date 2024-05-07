# frozen_string_literal: true

require 'hackle/internal/model/target'

module Hackle
  class TargetingType

    # @!attribute [r] supported_key_types
    #   @return [Array<TargetKeyType>]
    attr_reader :supported_key_types

    # @param supported_key_types [Array<TargetKeyType>]
    def initialize(supported_key_types)
      # @type [Array<TargetKeyType>]
      @supported_key_types = supported_key_types
    end

    # @param key_type [TargetKeyType]
    def supports?(key_type)
      @supported_key_types.include?(key_type)
    end

    IDENTIFIER = new(
      [
        TargetKeyType::SEGMENT
      ]
    )
    PROPERTY = new(
      [
        TargetKeyType::SEGMENT,
        TargetKeyType::USER_PROPERTY,
        TargetKeyType::HACKLE_PROPERTY,
        TargetKeyType::AB_TEST,
        TargetKeyType::FEATURE_FLAG
      ]
    )
    SEGMENT = new(
      [
        TargetKeyType::USER_ID,
        TargetKeyType::USER_PROPERTY,
        TargetKeyType::HACKLE_PROPERTY
      ]
    )
  end
end

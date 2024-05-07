# frozen_string_literal: true

require 'murmurhash3'

module Hackle
  class Bucketer

    # @param hasher [Hasher]
    def initialize(hasher:)
      # @type [Hasher]
      @hasher = hasher
    end

    # @param bucket [Bucket]
    # @param identifier [String]
    # @return [Slot, nil]
    def bucketing(bucket, identifier)
      slot_number = calculate_slot_number(seed: bucket.seed, slot_size: bucket.slot_size, value: identifier)
      bucket.get_slot_or_nil(slot_number)
    end

    # @param seed [Integer]
    # @param slot_size [Integer]
    # @param value [String]
    # @return [Integer]
    def calculate_slot_number(seed:, slot_size:, value:)
      hash_value = @hasher.hash(value, seed)
      hash_value.abs % slot_size
    end

  end

  class Hasher
    # @param data [String]
    # @param seed [Integer]
    # @return [Integer]
    def hash(data, seed)
      unsigned_value = MurmurHash3::V32.str_hash(data, seed)
      if (unsigned_value & 0x80000000).zero?
        unsigned_value
      else
        -((unsigned_value ^ 0xFFFFFFFF) + 1)
      end
    end
  end
end

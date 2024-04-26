# frozen_string_literal: true

require 'murmurhash3'

module Hackle
  class Bucketer

    # @param bucket [Bucket]
    # @param user [User]
    #
    # @return [Slot, nil]
    def bucketing(bucket:, user:)
      slot_number = calculate_slot_number(
        seed: bucket.seed,
        slot_size: bucket.slot_size,
        user_id: user.id
      )
      bucket.get_slot(slot_number: slot_number)
    end

    # @param seed [Integer]
    # @param slot_size [Integer]
    # @param user_id [String]
    #
    # @return [Integer]
    def calculate_slot_number(seed:, slot_size:, user_id:)
      hash_value = hash(data: user_id, seed: seed)
      hash_value.abs % slot_size
    end

    # @param data [String]
    # @param seed [Integer]
    #
    # @return [Integer]
    def hash(data:, seed:)
      unsigned_value = MurmurHash3::V32.str_hash(data, seed)
      if (unsigned_value & 0x80000000).zero?
        unsigned_value
      else
        -((unsigned_value ^ 0xFFFFFFFF) + 1)
      end
    end
  end
end

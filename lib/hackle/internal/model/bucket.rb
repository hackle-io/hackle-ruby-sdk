# frozen_string_literal: true

module Hackle

  class Bucket

    # @!attribute [r] id
    #   @return [Integer]
    # @!attribute [r] seed
    #   @return [Integer]
    # @!attribute [r] slot_size
    #   @return [Integer]
    # @!attribute [r] slots
    #   @return [Array<Slot>]
    attr_accessor :id, :seed, :slot_size, :slots

    # @param id [Integer]
    # @param seed [Integer]
    # @param slot_size [Integer]
    # @param slots [Array<Slot>]
    def initialize(id:, seed:, slot_size:, slots:)
      @id = id
      @seed = seed
      @slot_size = slot_size
      @slots = slots
    end

    # @param slot_number [Integer]
    # @return [Slot, nil]
    def get_slot_or_nil(slot_number)
      slots.each do |slot|
        return slot if slot.contains?(slot_number)
      end
      nil
    end
  end

  class Slot
    # @!attribute [r] variation_id
    #   @return [Integer]
    attr_reader :variation_id

    # @param start_inclusive [Integer]
    # @param end_exclusive [Integer]
    # @param variation_id [Integer]
    def initialize(start_inclusive:, end_exclusive:, variation_id:)
      @start_inclusive = start_inclusive
      @end_exclusive = end_exclusive
      @variation_id = variation_id
    end

    # @param slot_number [Integer]
    # @return [boolean]
    def contains?(slot_number)
      @start_inclusive <= slot_number && slot_number < @end_exclusive
    end
  end
end

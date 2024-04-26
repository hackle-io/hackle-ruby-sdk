module Hackle

  class Bucket

    # @!attribute [r] seed
    #  @return [Integer]
    # @!attribute [r] slot_size
    #  @return [Integer]
    attr_reader :seed, :slot_size

    # @param seed [Integer]
    # @param slot_size [Integer]
    # @param slots [Array]
    def initialize(seed:, slot_size:, slots:)
      @seed = seed
      @slot_size = slot_size
      @slots = slots
    end

    # @param slot_number [Integer]
    # @return [Slot, nil]
    def get_slot(slot_number:)
      @slots.find { |slot| slot.contains?(slot_number: slot_number) }
    end
  end
end

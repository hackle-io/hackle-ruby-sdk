module Hackle
  class Bucket
    attr_reader :seed, :slot_size

    def initialize(seed:, slot_size:, slots:)
      @seed = seed
      @slot_size = slot_size
      @slots = slots
    end

    def get_slot(slot_number:)
      @slots.find { |slot| slot.contains?(slot_number: slot_number) }
    end
  end
end

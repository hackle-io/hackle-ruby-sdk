module Hackle
  class Slot
    attr_reader :variation_id

    def initialize(start_inclusive, end_exclusive, variation_id)
      @start_inclusive = start_inclusive
      @end_exclusive = end_exclusive
      @variation_id = variation_id
    end

    def contains?(slot_number)
      @start_inclusive <= slot_number && slot_number < @end_exclusive
    end
  end
end

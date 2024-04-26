module Hackle
  class Slot
    # @!attribute variation_id
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
    def contains?(slot_number:)
      @start_inclusive <= slot_number && slot_number < @end_exclusive
    end
  end
end

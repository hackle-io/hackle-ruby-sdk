module Hackle
  class Variation

    # @!attribute id
    #   @return [Integer]
    # @!attribute key
    #   @return [String]
    # @!attribute dropped
    #   @return [boolean]
    attr_reader :id, :key, :dropped

    # @param id [Integer]
    # @param key [String]
    # @param dropped [boolean]
    def initialize(id:, key:, dropped:)
      @id = id
      @key = key
      @dropped = dropped
    end
  end
end

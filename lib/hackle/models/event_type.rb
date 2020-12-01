module Hackle
  class EventType

    # @!attribute [r] id
    #  @return [Integer]
    # @!attribute [r] key
    #  @return [String]
    attr_reader :id, :key

    # @param id [Integer]
    # @param key [String]
    def initialize(id:, key:)
      @id = id
      @key = key
    end

    # @param key [String]
    def self.undefined(key:)
      EventType.new(id: 0, key: key)
    end
  end
end

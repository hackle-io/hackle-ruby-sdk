# frozen_string_literal: true

module Hackle
  class EventType

    # @!attribute [r] id
    #   @return [Integer]
    # @!attribute [r] key
    #   @return [String]
    attr_accessor :id, :key

    # @param id [Integer]
    # @param key [String]
    def initialize(id:, key:)
      @id = id
      @key = key
    end
  end
end

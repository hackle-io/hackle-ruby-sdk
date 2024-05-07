# frozen_string_literal: true

module Hackle
  class Variation

    # @!attribute [r] id
    #   @return [Integer]
    # @!attribute [r] key
    #   @return [String]
    # @!attribute [r] is_dropped
    #   @return [boolean]
    # @!attribute [r] parameter_configuration_id
    #   @return [Integer]
    attr_reader :id, :key, :is_dropped, :parameter_configuration_id

    # @param id [Integer]
    # @param key [String]
    # @param is_dropped [boolean]
    # @param parameter_configuration_id [Integer, nil]
    def initialize(id:, key:, is_dropped:, parameter_configuration_id:)
      @id = id
      @key = key
      @is_dropped = is_dropped
      @parameter_configuration_id = parameter_configuration_id
    end
  end
end

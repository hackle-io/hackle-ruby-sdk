# frozen_string_literal: true

module Hackle
  class ParameterConfiguration

    # @!attribute [r] id
    #   @return [Integer]
    # @!attribute [r] parameters
    #   @return [Hash{String => Object}]
    attr_accessor :id, :parameters

    # @param id [Integer]
    # @param parameters [Hash{String => Object}]
    def initialize(id:, parameters:)
      @id = id
      @parameters = parameters
    end
  end
end

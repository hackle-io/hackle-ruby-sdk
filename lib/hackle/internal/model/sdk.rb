# frozen_string_literal: true

module Hackle
  class Sdk

    # @!attribute [r] name
    #   @return [String]
    # @!attribute [r] version
    #   @return [String]
    # @!attribute [r] key
    #   @return [String]
    attr_reader :name, :version, :key

    # @param name [String]
    # @param version [String]
    # @param key [String]
    def initialize(name:, version:, key:)
      @name = name
      @version = version
      @key = key
    end
  end
end

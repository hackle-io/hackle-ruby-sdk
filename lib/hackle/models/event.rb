module Hackle
  class Event

    # @!attribute [r] key
    #   @return [String]
    # @!attribute [r] value
    #   @return [Float, nil]
    # @!attribute [r] properties
    #   @return [Hash]
    attr_reader :key, :value, :properties


    # @param key [String]
    # @param value [Float, nil]
    # @param properties [Hash{Symbol => String, Number, boolean}]
    def initialize(key:, value:, properties:)
      @key = key
      @value = value
      @properties = properties
    end

    def valid?
      !key.nil? && key.is_a?(String)
    end
  end
end

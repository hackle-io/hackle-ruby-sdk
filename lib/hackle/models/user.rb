module Hackle

  class User

    # @!attribute [r] id
    #   @return [String]
    # @!attribute [r] properties
    #   @return [Hash]
    attr_reader :id, :properties

    #
    # @param id [String]
    # @param properties [Hash]
    #
    def initialize(id:, properties:)
      @id = id
      @properties = properties
    end

    def valid?
      !id.nil? && id.is_a?(String)
    end
  end
end
# frozen_string_literal: true

module Hackle
  class ValueType
    # @!attribute [r] name
    #   @return [String]
    attr_reader :name

    # @param name [String]
    def initialize(name)
      @name = name
    end

    def to_s
      name
    end

    NULL = new('NULL')
    UNKNOWN = new('UNKNOWN')
    STRING = new('STRING')
    NUMBER = new('NUMBER')
    BOOLEAN = new('BOOLEAN')
    VERSION = new('VERSION')
    JSON = new('JSON')

    @types = {
      'NULL' => NULL,
      'UNKNOWN' => UNKNOWN,
      'STRING' => STRING,
      'NUMBER' => NUMBER,
      'BOOLEAN' => BOOLEAN,
      'VERSION' => VERSION,
      'JSON' => JSON
    }.freeze

    # @param name [String]
    # @return [ValueType, nil]
    def self.from_or_nil(name)
      @types[name.upcase]
    end

    # @return [Array<ValueType>]
    def self.values
      @types.values
    end

    class << self
      def string?(value)
        return false if value.nil?

        value.is_a?(String)
      end

      def empty_string?(value)
        string?(value) && value.empty?
      end

      def not_empty_string?(value)
        string?(value) && !value.empty?
      end

      def number?(value)
        return false if value.nil?

        value.is_a?(Numeric)
      end

      def boolean?(value)
        return false if value.nil?

        value.is_a?(TrueClass) || value.is_a?(FalseClass)
      end
    end
  end
end

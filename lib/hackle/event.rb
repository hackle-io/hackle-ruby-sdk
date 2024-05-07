# frozen_string_literal: true

require 'hackle/internal/properties/properties_builder'

module Hackle
  class Event
    # @return [String]
    attr_reader :key

    # @return [Float, nil]
    attr_reader :value

    # @return [Hash{String => Object}]
    attr_reader :properties

    # @param key [String]
    # @param value [Numeric, nil]
    # @param properties [Hash{String => Object}]
    def initialize(key:, value:, properties:)
      @key = key
      @value = value
      @properties = properties
    end

    # @return [boolean]
    def valid?
      error_or_nil.nil?
    end

    # @return [String, nil]
    def error_or_nil
      return "Invalid event key: #{key} (expected: not empty string)" unless ValueType.not_empty_string?(key)
      return "Invalid event value: #{value} (expected: number)" if !value.nil? && !ValueType.number?(value)
      return "Invalid event properties: #{properties} (expected: Hash)" if !properties.nil? && !properties.is_a?(Hash)

      nil
    end

    def ==(other)
      other.is_a?(Event) && other.key == key && other.value == value && other.properties == properties
    end

    def to_s
      "Hackle::Event(key: #{key}, value: #{value}, properties: #{properties})"
    end

    # @param key [String]
    # @return [Hackle::Event::Builder]
    def self.builder(key)
      Builder.new(key)
    end

    class Builder
      # @param key [String]
      def initialize(key)
        @key = key
        @value = nil
        @properties = PropertiesBuilder.new
      end

      # @param value [Float, nil]
      # @return [Hackle::Event::Builder]
      def value(value)
        @value = value
        self
      end

      # @param key [String]
      # @param value [Object, nil]
      # @return [Hackle::Event::Builder]
      def property(key, value)
        @properties.add(key, value)
        self
      end

      # @param properties [Hash{String => Object}]
      # @return [Hackle::Event::Builder]
      def properties(properties)
        @properties.add_all(properties)
        self
      end

      # @return [Hackle::Event]
      def build
        Event.new(key: @key, value: @value, properties: @properties.build)
      end
    end
  end
end

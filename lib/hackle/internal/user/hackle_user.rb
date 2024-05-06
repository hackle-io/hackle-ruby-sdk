# frozen_string_literal: true

require 'hackle/internal/identifiers/identifier_builder'
require 'hackle/internal/properties/properties_builder'

module Hackle
  class HackleUser

    # @return [Hash{String => String}]
    attr_reader :identifiers

    # @return [Hash{String => Object}]
    attr_reader :properties

    # @param identifiers [Hash{String => String}]
    # @param properties [Hash{String => Object}]
    def initialize(identifiers:, properties:)
      @identifiers = identifiers
      @properties = properties
    end

    def ==(other)
      other.is_a?(Hackle::HackleUser) && identifiers == other.identifiers && properties == other.properties
    end

    def self.builder
      Builder.new
    end

    class Builder
      def initialize
        @identifiers = IdentifiersBuilder.new
        @properties = PropertiesBuilder.new
      end

      # @param type [String]
      # @param value [String, nil]
      # @return [Builder]
      def identifier(type, value)
        @identifiers.add(type, value)
        self
      end

      # @param identifiers [Hash{String => String}]
      # @return [Builder]
      def identifiers(identifiers)
        @identifiers.add_all(identifiers)
        self
      end

      # @param key [String]
      # @param value [Object, nil]
      # @return [Builder]
      def property(key, value)
        @properties.add(key, value)
        self
      end

      # @param properties [Hash{String => Object}]
      # @return [Builder]
      def properties(properties)
        @properties.add_all(properties)
        self
      end

      def build
        HackleUser.new(
          identifiers: @identifiers.build,
          properties: @properties.build
        )
      end
    end
  end
end

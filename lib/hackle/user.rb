# frozen_string_literal: true

require 'hackle/internal/identifiers/identifier_builder'
require 'hackle/internal/properties/properties_builder'

module Hackle
  class User
    # @return [String, nil]
    attr_reader :id

    # @return [String, nil]
    attr_reader :user_id

    # @return [String, nil]
    attr_reader :device_id

    # @return [Hash{String => String}]
    attr_reader :identifiers

    # @return [Hash{String => Object}]
    attr_reader :properties

    # @param id [String, nil]
    # @param user_id [String, nil]
    # @param device_id [String, nil]
    # @param identifiers [Hash{String => String}]
    # @param properties [Hash{String => Object}]
    def initialize(id:, user_id:, device_id:, identifiers:, properties:)
      @id = id
      @user_id = user_id
      @device_id = device_id
      @identifiers = identifiers
      @properties = properties
    end

    def ==(other)
      return false unless other.is_a?(User)

      id == other.id &&
        user_id == other.user_id &&
        device_id == other.device_id &&
        identifiers == other.identifiers &&
        properties == other.properties
    end

    def to_s
      "Hackle::User(id: #{id}, user_id: #{user_id}, device_id: #{device_id}, identifiers: #{identifiers}, properties: #{properties})"
    end

    # @return [User::Builder]
    def self.builder
      Builder.new
    end

    class Builder
      def initialize
        @identifiers = IdentifiersBuilder.new
        @properties = PropertiesBuilder.new
      end

      # @param id [String, Numeric]
      # @return [User::Builder]
      def id(id)
        @id = IdentifiersBuilder.sanitize_value_or_nil(id)
        self
      end

      # @param user_id [String, Numeric]
      # @return [User::Builder]
      def user_id(user_id)
        @user_id = IdentifiersBuilder.sanitize_value_or_nil(user_id)
        self
      end

      # @param device_id [String, Numeric]
      # @return [User::Builder]
      def device_id(device_id)
        @device_id = IdentifiersBuilder.sanitize_value_or_nil(device_id)
        self
      end

      # @param identifier_type [String]
      # @param identifier_value [String, nil]
      # @return [User::Builder]
      def identifier(identifier_type, identifier_value)
        @identifiers.add(identifier_type, identifier_value)
        self
      end

      # @param identifiers [Hash{String => String}]
      # @return [User::Builder]
      def identifiers(identifiers)
        @identifiers.add_all(identifiers)
        self
      end

      # @param key [String]
      # @param value [Object, nil]
      # @return [User::Builder]
      def property(key, value)
        @properties.add(key, value)
        self
      end

      # @param properties [Hash{String => Object}]
      # @return [User::Builder]
      def properties(properties)
        @properties.add_all(properties)
        self
      end

      # @return [User]
      def build
        User.new(
          id: @id,
          user_id: @user_id,
          device_id: @device_id,
          identifiers: @identifiers.build,
          properties: @properties.build
        )
      end
    end
  end
end

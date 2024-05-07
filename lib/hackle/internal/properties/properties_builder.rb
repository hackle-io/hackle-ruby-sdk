# frozen_string_literal: true

require 'hackle/internal/logger/logger'

module Hackle
  class PropertiesBuilder
    def initialize
      # @type [Hash{String => Object}]
      @properties = {}
    end

    # @param key [String]
    # @param value [Object, nil]
    # @return [Hackle::PropertiesBuilder]
    def add(key, value)
      return self if @properties.length >= MAX_PROPERTIES_COUNT

      unless valid_key?(key)
        Log.get.warn { "Invalid property key: #{key} (expected: string[1..128])" }
        return self
      end

      sanitized_value = sanitize_value_or_nil(key, value)
      @properties[key] = sanitized_value unless sanitized_value.nil?
      self
    end

    # @param properties [Hash{String => Object}]
    # @return [Hackle::PropertiesBuilder]
    def add_all(properties)
      if properties.nil? || !properties.is_a?(Hash)
        Log.get.warn { "Invalid properties: #{properties} (expected: Hash{String => Object})" }
        return self
      end

      properties.each { |key, value| add(key, value) }
      self
    end

    # @return [Hash{String (frozen)->Object}]
    def build
      @properties.dup
    end

    private

    SYSTEM_PROPERTY_KEY_PREFIX = '$'
    MAX_PROPERTIES_COUNT = 128
    MAX_PROPERTY_KEY_LENGTH = 128
    MAX_PROPERTY_VALUE_LENGTH = 1024

    # @param key [String]
    # @param value [Object, nil]
    # @return [Object, nil]
    def sanitize_value_or_nil(key, value)
      return nil if value.nil?
      return value.filter { |it| valid_element?(it) } if value.is_a?(Array)
      return value if valid_value?(value)
      return value if key.start_with?(SYSTEM_PROPERTY_KEY_PREFIX)

      nil
    end

    # @param key [String]
    # @return [boolean]
    def valid_key?(key)
      return false if key.nil?
      return false unless key.is_a?(String)
      return false if key.empty?
      return false if key.length > MAX_PROPERTY_KEY_LENGTH

      true
    end

    # @param value [Object]
    # @return [boolean]
    def valid_value?(value)
      case value
      when String
        value.length <= MAX_PROPERTY_VALUE_LENGTH
      when Numeric, TrueClass, FalseClass
        true
      else
        false
      end
    end

    # @param element [Object]
    # @return [boolean]
    def valid_element?(element)
      case element
      when String
        element.length <= MAX_PROPERTY_VALUE_LENGTH
      when Numeric
        true
      else
        false
      end
    end
  end
end

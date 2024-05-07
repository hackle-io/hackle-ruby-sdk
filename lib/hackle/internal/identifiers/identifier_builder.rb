# frozen_string_literal: true

require 'hackle/internal/logger/logger'

module Hackle
  class IdentifiersBuilder
    def initialize
      # @type [Hash{String => String}]
      @identifiers = {}
    end

    # @param identifier_type [String]
    # @param identifier_value [String, nil]
    # @return [Hackle::IdentifiersBuilder]
    def add(identifier_type, identifier_value)
      value = IdentifiersBuilder.sanitize_value_or_nil(identifier_value)

      if valid_type?(identifier_type) && !value.nil?
        @identifiers[identifier_type] = value
      else
        Log.get.warn { "Invalid user identifier [type=#{identifier_type}] value=#{identifier_value}]" }
      end

      self
    end

    # @param identifiers [Hash]
    # @return [Hackle::IdentifiersBuilder]
    def add_all(identifiers)
      identifiers.each do |identifier_type, identifier_value|
        add(identifier_type, identifier_value)
      end
      self
    end

    # @return [Hash{String => String}]
    def build
      @identifiers.dup
    end

    def self.sanitize_value_or_nil(identifier_value)
      return nil if identifier_value.nil?

      if identifier_value.is_a?(String) && !identifier_value.empty? && identifier_value.length <= MAX_IDENTIFIER_VALUE_LENGTH
        return identifier_value
      end

      return identifier_value.to_s if identifier_value.is_a?(Numeric)

      nil
    end

    private

    MAX_IDENTIFIER_TYPE_LENGTH = 128
    MAX_IDENTIFIER_VALUE_LENGTH = 512

    def valid_type?(identifier_type)
      return false if identifier_type.nil?
      return false unless identifier_type.is_a?(String)
      return false if identifier_type.empty?
      return false if identifier_type.length > MAX_IDENTIFIER_TYPE_LENGTH

      true
    end
  end
end

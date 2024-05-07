# frozen_string_literal: true

module Hackle
  class ParameterConfig

    # @return [Hash{String => Object}]
    attr_reader :parameters

    # @param parameters [Hash{String => Object}]
    def initialize(parameters)
      @parameters = parameters
    end

    @empty = new({})

    # @return [Hackle::ParameterConfig]
    def self.empty
      @empty
    end

    def ==(other)
      other.is_a?(self.class) && other.parameters == parameters
    end

    def to_s
      "Hackle::ParameterConfig(#{parameters})"
    end

    # @param key [String]
    # @param default_value [Object, nil]
    # @return [Object, nil]
    def get(key, default_value = nil)
      parameter_value = parameters.fetch(key, default_value)

      return default_value if parameter_value.nil?
      return parameter_value if default_value.nil?

      case default_value
      when String
        parameter_value.is_a?(String) ? parameter_value : default_value
      when Numeric
        parameter_value.is_a?(Numeric) ? parameter_value : default_value
      when TrueClass, FalseClass
        parameter_value.is_a?(TrueClass) || parameter_value.is_a?(FalseClass) ? parameter_value : default_value
      else
        default_value
      end
    end
  end
end

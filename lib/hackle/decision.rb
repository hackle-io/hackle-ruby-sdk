# frozen_string_literal: true

module Hackle
  class ExperimentDecision

    # @return [String]
    attr_reader :variation

    # @return [String]
    attr_reader :reason

    # @return [ParameterConfig]
    attr_reader :config

    # @param variation [String]
    # @param reason [String]
    # @param config [ParameterConfig]
    def initialize(variation, reason, config)
      @config = config
      @variation = variation
      @reason = reason
    end

    # @param key [String]
    # @param default_value [Object, nil]
    # @return [Object, nil]
    def get(key, default_value = nil)
      config.get(key, default_value)
    end

    def ==(other)
      other.is_a?(self.class) &&
        variation == other.variation &&
        reason == other.reason &&
        config == other.config
    end

    def to_s
      "ExperimentDecision(variation=#{variation}, reason=#{reason}, config=#{config})"
    end

  end

  class FeatureFlagDecision

    # @return [boolean]
    attr_accessor :is_on

    # @return [String]
    attr_accessor :reason

    # @return [ParameterConfig]
    attr_reader :config

    # @param is_on [boolean]
    # @param reason [String]
    # @param config [ParameterConfig]
    def initialize(is_on, reason, config)
      @is_on = is_on
      @reason = reason
      @config = config
    end

    # @return [boolean]
    def on?
      @is_on
    end

    # @param key [String]
    # @param default_value [Object, nil]
    # @return [Object, nil]
    def get(key, default_value = nil)
      config.get(key, default_value)
    end

    def ==(other)
      other.is_a?(FeatureFlagDecision) &&
        is_on == other.is_on &&
        reason == other.reason &&
        config == other.config
    end

    def to_s
      "FeatureFlagDecision(is_on=#{is_on}, reason=#{reason}, config=#{config})"
    end
  end

  class RemoteConfigDecision

    # @return [Object, nil]
    attr_reader :value

    # @return [String]
    attr_reader :reason

    # @param value [Object, nil]
    # @param reason [String]
    def initialize(value, reason)
      @value = value
      @reason = reason
    end

    def ==(other)
      other.is_a?(RemoteConfigDecision) &&
        value == other.value &&
        reason == other.reason
    end

    def to_s
      "RemoteConfigDecision(value=#{value}, reason=#{reason})"
    end
  end
end

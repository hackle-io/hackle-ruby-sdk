# frozen_string_literal: true

module Hackle
  class RemoteConfig
    # @param user [Hackle::User]
    # @param user_resolver [Hackle::HackleUserResolver]
    # @param core [Hackle::Core]
    def initialize(user:, user_resolver:, core:)
      # @type [Hackle::User]
      @user = user

      # @type [Hackle::HackleUserResolver]
      @user_resolver = user_resolver

      # @type [Hackle::Core]
      @core = core
    end

    # @param key [String]
    # @param default_value [Object, nil]
    # @return [Object, nil]
    def get(key, default_value = nil)
      case default_value
      when nil
        decision(key, default_value, ValueType::NULL).value
      when String
        decision(key, default_value, ValueType::STRING).value
      when Numeric
        decision(key, default_value, ValueType::NUMBER).value
      when TrueClass, FalseClass
        decision(key, default_value, ValueType::BOOLEAN).value
      else
        decision(key, default_value, ValueType::UNKNOWN).value
      end

    end

    private

    # @param key [String]
    # @param default_value [Object, nil]
    # @param required_type [Hackle::ValueType]
    # @return [Hackle::RemoteConfigDecision]
    def decision(key, default_value, required_type)
      hackle_user = @user_resolver.resolve_or_nil(@user)
      return RemoteConfigDecision.new(default_value, DecisionReason::INVALID_INPUT) if hackle_user.nil?
      return RemoteConfigDecision.new(default_value, DecisionReason::INVALID_INPUT) if key.nil?

      @core.remote_config(key, hackle_user, required_type, default_value)
    rescue => e
      Log.get.error { "Unexpected error while deciding remote config parameter[#{key}]. Returning default value: #{e.inspect}" }
      RemoteConfigDecision.new(default_value, DecisionReason::EXCEPTION)
    end
  end
end

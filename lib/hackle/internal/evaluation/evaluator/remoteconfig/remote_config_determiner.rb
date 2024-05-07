# frozen_string_literal: true

module Hackle
  class RemoteConfigTargetRuleDeterminer

    # @param matcher [RemoteConfigTargetRuleMatcher]
    def initialize(matcher:)
      # @type [RemoteConfigTargetRuleMatcher]
      @matcher = matcher
    end

    # @param request [RemoteConfigRequest]
    # @param context [EvaluatorContext]
    # @return [RemoteConfigTargetRule, nil]
    def determine_or_nil(request, context)
      request.parameter.target_rules.find { |it| @matcher.matches(request, context, it) }
    end
  end

  class RemoteConfigTargetRuleMatcher
    # @param target_matcher [TargetMatcher]
    # @param bucketer [Bucketer]
    def initialize(target_matcher:, bucketer:)
      # @type [TargetMatcher]
      @target_matcher = target_matcher
      # @type [Bucketer]
      @bucketer = bucketer
    end

    # @param request [RemoteConfigRequest]
    # @param context [EvaluatorContext]
    # @param target_rule [RemoteConfigTargetRule]
    # @return [boolean]
    def matches(request, context, target_rule)
      matches = @target_matcher.matches(request, context, target_rule.target)
      return false unless matches

      identifier = request.user.identifiers[request.parameter.identifier_type]
      return false if identifier.nil?

      bucket = request.workspace.get_bucket_or_nil(target_rule.bucket_id)
      raise ArgumentError, "bucket [#{target_rule.bucket_id}]" if bucket.nil?

      allocated = @bucketer.bucketing(bucket, identifier)
      !allocated.nil?
    end
  end
end

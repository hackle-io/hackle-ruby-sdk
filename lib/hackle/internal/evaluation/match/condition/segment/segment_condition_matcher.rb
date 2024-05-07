# frozen_string_literal: true

require 'hackle/internal/model/target'
require 'hackle/internal/evaluation/match/condition/condition_matcher'

module Hackle
  class SegmentConditionMatcher
    include ConditionMatcher

    # @param segment_matcher [SegmentMatcher]
    def initialize(segment_matcher:)
      # @type [SegmentMatcher]
      @segment_matcher = segment_matcher
    end

    def matches(request, context, condition)
      if condition.key.type != TargetKeyType::SEGMENT
        raise ArgumentError, "unsupported TargetKeyType [#{condition.key.type}]"
      end

      matches = condition.match.values.any? { |it| value_matches(request, context, it) }
      TargetMatchType.matches(condition.match.type, matches)
    end

    private

    # @param request [EvaluatorRequest]
    # @param context [EvaluatorContext]
    # @param value [Object]
    # @return [boolean]
    def value_matches(request, context, value)
      segment_key = value
      raise ArgumentError, "segment key [#{value}]" unless segment_key.is_a?(String)

      segment = request.workspace.get_segment_or_nil(segment_key)
      raise ArgumentError, "segment [#{segment_key}]" unless segment

      @segment_matcher.matches(request, context, segment)
    end
  end

  class SegmentMatcher
    # @param user_condition_matcher [ConditionMatcher]
    def initialize(user_condition_matcher:)
      # @type [ConditionMatcher]
      @user_condition_matcher = user_condition_matcher
    end

    # @param request [EvaluatorRequest]
    # @param context [EvaluatorContext]
    # @param segment [Segment]
    # @return [boolean]
    def matches(request, context, segment)
      segment.targets.any? { |it| target_matches(request, context, it) }
    end

    private

    # @param request [EvaluatorRequest]
    # @param context [EvaluatorContext]
    # @param target [Target]
    # @return [boolean]
    def target_matches(request, context, target)
      target.conditions.all? { |it| @user_condition_matcher.matches(request, context, it) }
    end
  end
end

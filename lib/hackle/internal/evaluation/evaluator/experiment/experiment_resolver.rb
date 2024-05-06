# frozen_string_literal: true

require 'hackle/internal/model/action'
require 'hackle/internal/evaluation/bucketer/bucketer'

module Hackle
  class ExperimentActionResolver
    # @param bucketer [Bucketer]
    def initialize(bucketer:)
      # @type [Bucketer]
      @bucketer = bucketer
    end

    # @param request [ExperimentRequest]
    # @param action [Action]
    # @return [Hackle::Variation, nil]
    def resolve_or_nil(request, action)
      case action.type
      when ActionType::VARIATION
        resolve_variation(request, action)
      when ActionType::BUCKET
        resolve_bucket(request, action)
      else
        raise ArgumentError, "unsupported ActionType [#{action.type}]"
      end
    end

    private

    # @param request [ExperimentRequest]
    # @param action [Action]
    # @return [Hackle::Variation]
    def resolve_variation(request, action)
      variation_id = action.variation_id
      raise ArgumentError, "action variation [#{request.experiment.id}]" if variation_id.nil?

      variation = request.experiment.get_variation_or_nil_by_id(variation_id)
      raise ArgumentError, "variation [#{variation_id}]" if variation.nil?

      variation
    end

    # @param request [ExperimentRequest]
    # @param action [Action]
    # @return [Hackle::Variation, nil]
    def resolve_bucket(request, action)
      bucket_id = action.bucket_id
      raise ArgumentError, "action bucket [#{request.experiment.id}]" if bucket_id.nil?

      bucket = request.workspace.get_bucket_or_nil(bucket_id)
      raise ArgumentError, "bucket [#{bucket_id}]" if bucket.nil?

      identifier = request.user.identifiers[request.experiment.identifier_type]
      return nil if identifier.nil?

      slot = @bucketer.bucketing(bucket, identifier)
      return nil if slot.nil?

      request.experiment.get_variation_or_nil_by_id(slot.variation_id)
    end
  end

  class ExperimentOverrideResolver
    # @param target_matcher [TargetMatcher]
    # @param action_resolver [ExperimentActionResolver]

    def initialize(target_matcher:, action_resolver:)
      # @type [TargetMatcher]
      @target_matcher = target_matcher
      # @type [ExperimentActionResolver]
      @action_resolver = action_resolver
    end

    # @param request [ExperimentRequest]
    # @param context [EvaluatorContext]
    # @return [Hackle::Variation, nil]
    def resolve_or_nil(request, context)
      resolve_user_override(request) || resolve_segment_override(request, context)
    end

    private

    # @param request [ExperimentRequest]
    # @return [Hackle::Variation, nil]
    def resolve_user_override(request)
      identifier = request.user.identifiers[request.experiment.identifier_type]
      return nil if identifier.nil?

      overridden_variation_id = request.experiment.user_overrides[identifier]
      return nil if overridden_variation_id.nil?

      request.experiment.get_variation_or_nil_by_id(overridden_variation_id)
    end

    # @param request [ExperimentRequest]
    # @param context [EvaluatorContext]
    # @return [Hackle::Variation, nil]
    def resolve_segment_override(request, context)
      overridden_rule = request.experiment.segment_overrides.find do |it|
        @target_matcher.matches(request, context, it.target)
      end
      return nil if overridden_rule.nil?

      @action_resolver.resolve_or_nil(request, overridden_rule.action)
    end
  end

  class ExperimentContainerResolver
    # @param bucketer [Bucketer]
    def initialize(bucketer:)
      # @type [Bucketer]
      @bucketer = bucketer
    end

    # @param request [ExperimentRequest]
    # @param container [Container]
    def user_in_container_group?(request, container)

      identifier = request.user.identifiers[request.experiment.identifier_type]
      return false if identifier.nil?

      bucket = request.workspace.get_bucket_or_nil(container.bucket_id)
      raise ArgumentError, "bucket [#{container.bucket_id}]" if bucket.nil?

      slot = @bucketer.bucketing(bucket, identifier)
      return false if slot.nil?

      group = container.get_group_or_nil(slot.variation_id)
      raise ArgumentError, "container group [#{slot.variation_id}]" if group.nil?

      group.experiments.include?(request.experiment.id)
    end
  end

  class ExperimentTargetDeterminer

    # @param target_matcher [TargetMatcher]
    def initialize(target_matcher:)
      # @type [TargetMatcher]
      @target_matcher = target_matcher
    end

    # @param request [ExperimentRequest]
    # @param context [EvaluatorContext]
    def user_in_experiment_target?(request, context)
      return true if request.experiment.target_audiences.empty?

      request.experiment.target_audiences.any? { |it| @target_matcher.matches(request, context, it) }
    end
  end

  class ExperimentTargetRuleDeterminer
    # @param target_matcher [TargetMatcher]
    def initialize(target_matcher:)
      # @type [TargetMatcher]
      @target_matcher = target_matcher
    end

    # @param request [ExperimentRequest]
    # @param context [EvaluatorContext]
    # @return [Hackle::TargetRule, nil]
    def determine_target_rule_or_nil(request, context)
      request.experiment.target_rules.find { |it| @target_matcher.matches(request, context, it.target) }
    end
  end
end

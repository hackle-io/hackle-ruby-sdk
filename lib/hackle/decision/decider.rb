# frozen_string_literal: true

module Hackle
  class Decision

    class NotAllocated < Decision
    end

    class ForcedAllocated < Decision
      # @return [String]
      attr_reader :variation_key

      # @param variation_key [String]
      def initialize(variation_key:)
        @variation_key = variation_key
      end
    end

    class NaturalAllocated < Decision
      # @return [Variation]
      attr_reader :variation

      # @param variation [Variation]
      def initialize(variation:)
        @variation = variation
      end
    end
  end

  class Decider
    def initialize
      @bucketer = Bucketer.new
    end

    # @param experiment [Experiment]
    # @param user [User]
    #
    # @return [Decision]
    def decide(experiment:, user:)
      case experiment
      when Experiment::Completed
        Decision::ForcedAllocated.new(variation_key: experiment.winner_variation_key)
      when Experiment::Running
        decide_running(running_experiment: experiment, user: user)
      else
        NotAllocated.new
      end
    end

    # @param running_experiment [Experiment::Running]
    # @param user [User]
    #
    # @return [Decision]
    def decide_running(running_experiment:, user:)

      overridden_variation = running_experiment.get_overridden_variation(user: user)
      return Decision::ForcedAllocated.new(variation_key: overridden_variation.key) unless overridden_variation.nil?

      allocated_slot = @bucketer.bucketing(bucket: running_experiment.bucket, user: user)
      return Decision::NotAllocated.new if allocated_slot.nil?

      allocated_variation = running_experiment.get_variation(variation_id: allocated_slot.variation_id)
      return Decision::NotAllocated.new if allocated_variation.nil?
      return Decision::NotAllocated.new if allocated_variation.dropped

      Decision::NaturalAllocated.new(variation: allocated_variation)
    end
  end
end

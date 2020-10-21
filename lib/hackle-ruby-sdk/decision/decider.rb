# frozen_string_literal: true

module Hackle
  class Decision
    class NotAllocated < Decision
    end

    class ForcedAllocated < Decision
      attr_reader :variation_key

      def initialize(variation_key)
        @variation_key = variation_key
      end
    end

    class NaturalAllocated < Decision
      attr_reader :variation

      def initialize(variation)
        @variation = variation
      end
    end
  end

  class Decider
    def initialize
      @bucketer = Bucketer.new
    end

    def decide(experiment, user_id)
      case experiment
      when Experiment::Completed
        Decision::ForcedAllocated.new(experiment.winner_variation_key)
      when Experiment::Running
        decide_running(experiment, user_id)
      end
    end

    def decide_running(experiment, user_id)

      overridden_variation = experiment.get_overridden_variation(user_id)
      return Decision::ForcedAllocated.new(overridden_variation.key) unless overridden_variation.nil?

      allocated_slot = @bucketer.bucketing(experiment.bucket, user_id)
      return Decision::NotAllocated.new if allocated_slot.nil?

      allocated_variation = experiment.get_variation(allocated_slot.variation_id)
      return Decision::NotAllocated.new if allocated_variation.nil?
      return Decision::NotAllocated.new if allocated_variation.dropped

      Decision::NaturalAllocated.new(allocated_variation)
    end
  end
end

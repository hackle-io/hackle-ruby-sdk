module Hackle
  class Workspace
    def initialize(experiments, event_types)
      @experiments = experiments
      @event_types = event_types
    end

    def get_experiment(experiment_key)
      @experiments[experiment_key]
    end

    def get_event_type(event_type_key)
      @event_types[event_type_key]
    end

    class << self
      def create(data)
        buckets = Hash[data[:buckets].map { |b| [b[:id], bucket(b)] }]
        running_experiments = Hash[data[:experiments].map { |re| [re[:key], running_experiment(re, buckets)] }]
        completed_experiment = Hash[data[:completedExperiments].map { |ce| [ce[:experimentKey], completed_experiment(ce)] }]
        event_types = Hash[data[:events].map { |e| [e[:key], event_type(e)] }]
        experiments = running_experiments.merge(completed_experiment)
        Workspace.new(experiments, event_types)
      end

      private

      def running_experiment(data, buckets)
        Experiment::Running.new(
          data[:id],
          data[:key],
          buckets[data[:bucketId]],
          Hash[data[:variations].map { |v| [v[:id], variation(v)] }],
          Hash[data[:execution][:userOverrides].map { |u| [u[:userId], u[:variationId]] }]
        )
      end

      def completed_experiment(data)
        Experiment::Completed.new(
          data[:experimentId],
          data[:experimentKey],
          data[:winnerVariationKey]
        )
      end

      def variation(data)
        Variation.new(
          data[:id],
          data[:key],
          data[:status] == 'DROPPED'
        )
      end

      def bucket(data)
        Bucket.new(
          data[:seed],
          data[:slotSize],
          data[:slots].map { |s| slot(s) }
        )
      end

      def slot(data)
        Slot.new(
          data[:startInclusive],
          data[:endExclusive],
          data[:variationId]
        )
      end

      def event_type(data)
        EventType.new(
          data[:id],
          data[:key]
        )
      end
    end
  end
end

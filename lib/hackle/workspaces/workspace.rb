module Hackle
  class Workspace
    def initialize(experiments:, event_types:)
      @experiments = experiments
      @event_types = event_types
    end

    def get_experiment(experiment_key:)
      @experiments[experiment_key]
    end

    def get_event_type(event_type_key:)
      event_type = @event_types[event_type_key]

      if event_type.nil?
        EventType.undefined(key: event_type_key)
      else
        event_type
      end
    end

    class << self
      def create(data:)
        buckets = Hash[data[:buckets].map { |b| [b[:id], bucket(b)] }]
        running_experiments = Hash[data[:experiments].map { |re| [re[:key], running_experiment(re, buckets)] }]
        completed_experiment = Hash[data[:completedExperiments].map { |ce| [ce[:experimentKey], completed_experiment(ce)] }]
        event_types = Hash[data[:events].map { |e| [e[:key], event_type(e)] }]
        experiments = running_experiments.merge(completed_experiment)
        Workspace.new(
          experiments: experiments,
          event_types: event_types
        )
      end

      private

      def running_experiment(data, buckets)
        Experiment::Running.new(
          id: data[:id],
          key: data[:key],
          bucket: buckets[data[:bucketId]],
          variations: Hash[data[:variations].map { |v| [v[:id], variation(v)] }],
          user_overrides: Hash[data[:execution][:userOverrides].map { |u| [u[:userId], u[:variationId]] }]
        )
      end

      def completed_experiment(data)
        Experiment::Completed.new(
          id: data[:experimentId],
          key: data[:experimentKey],
          winner_variation_key: data[:winnerVariationKey]
        )
      end

      def variation(data)
        Variation.new(
          id: data[:id],
          key: data[:key],
          dropped: data[:status] == 'DROPPED'
        )
      end

      def bucket(data)
        Bucket.new(
          seed: data[:seed],
          slot_size: data[:slotSize],
          slots: data[:slots].map { |s| slot(s) }
        )
      end

      def slot(data)
        Slot.new(
          start_inclusive: data[:startInclusive],
          end_exclusive: data[:endExclusive],
          variation_id: data[:variationId]
        )
      end

      def event_type(data)
        EventType.new(
          id: data[:id],
          key: data[:key]
        )
      end
    end
  end
end

# frozen_string_literal: true

require 'hackle/internal/evaluation/evaluator/experiment/experiment_evaluator'

module Hackle
  class UserEventFactory
    # @param clock [Clock]
    def initialize(clock:)
      # @type [Clock]
      @clock = clock
    end

    # @param request [EvaluatorRequest]
    # @param evaluation [EvaluatorEvaluation]
    # @return [Array<UserEvent>]
    def create(request, evaluation)
      timestamp = @clock.current_millis
      events = []

      root_event = create_internal(request, evaluation, timestamp, PropertiesBuilder.new)
      events << root_event unless root_event.nil?

      evaluation.target_evaluations.each do |target_evaluation|
        properties_builder = PropertiesBuilder.new
        properties_builder.add('$targetingRootType', request.key.type)
        properties_builder.add('$targetingRootId', request.key.id)
        target_event = create_internal(request, target_evaluation, timestamp, properties_builder)
        events << target_event unless target_event.nil?
      end

      events
    end

    private

    # @param request [EvaluatorRequest]
    # @param evaluation [EvaluatorEvaluation]
    # @param timestamp [Integer]
    # @param properties_builder [PropertiesBuilder]
    # @return [UserEvent, nil]
    def create_internal(request, evaluation, timestamp, properties_builder)
      e = evaluation
      case e
      when ExperimentEvaluation
        properties_builder.add('$parameterConfigurationId', e.config&.id)
        properties_builder.add('$experiment_version', e.experiment.version)
        properties_builder.add('$execution_version', e.experiment.execution_version)
        UserEvent.exposure(e, properties_builder.build, request.user, timestamp)
      when RemoteConfigEvaluation
        properties_builder.add_all(e.properties)
        UserEvent.remote_config(e, properties_builder.build, request.user, timestamp)
      else
        Log.get.error { "unsupported evaluator evaluation: #{e.class}" }
        nil
      end
    end
  end
end

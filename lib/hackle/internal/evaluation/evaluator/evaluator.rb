# frozen_string_literal: true

module Hackle

  module Evaluator
    # @param request [EvaluatorRequest]
    # @param context [EvaluatorContext]
    # @return [EvaluatorEvaluation]
    def evaluate(request, context) end

    # @return [EvaluatorContext]
    def self.context
      EvaluatorContext.new
    end
  end

  class EvaluatorRequest

    # @return [EvaluatorKey]
    attr_reader :key

    # @return [Workspace]
    attr_reader :workspace

    # @return [HackleUser]
    attr_reader :user

    # @param key [EvaluatorKey]
    # @param workspace [Workspace]
    # @param user [HackleUser]
    def initialize(key:, workspace:, user:)
      @key = key
      @workspace = workspace
      @user = user
    end

    def ==(other)
      other.is_a?(EvaluatorRequest) && key == other.key
    end
  end

  class EvaluatorEvaluation

    # @return [String]
    attr_reader :reason

    # @return [Array<EvaluatorEvaluation>]
    attr_reader :target_evaluations

    # @param reason [String]
    # @param target_evaluations [Array<EvaluatorEvaluation>]
    def initialize(reason:, target_evaluations:)
      @reason = reason
      @target_evaluations = target_evaluations
    end
  end

  class EvaluatorContext

    def initialize
      # @type [Array<EvaluatorRequest>]
      @requests = []
      # @type [Array<EvaluatorEvaluation>]
      @evaluations = []
    end

    # @return [Array<EvaluatorRequest>]
    def requests
      @requests.dup
    end

    # @param request [EvaluatorRequest]
    # @return [boolean]
    def request_include?(request)
      @requests.include?(request)
    end

    # @param request [EvaluatorRequest]
    def add_request(request)
      @requests << request
    end

    # @param request [EvaluatorRequest]
    def remove_request(request)
      @requests.delete(request)
    end

    # @return [Array<EvaluatorEvaluation>]
    def evaluations
      @evaluations.dup
    end

    # @param evaluation [EvaluatorEvaluation]
    def add_evaluation(evaluation)
      @evaluations << evaluation
    end
  end

  class EvaluatorKey
    # @return [String]
    attr_reader :type

    # @return [Integer]
    attr_reader :id

    # @param type [String]
    # @param id [Integer]
    def initialize(type:, id:)
      @type = type
      @id = id
    end

    def ==(other)
      other.is_a?(EvaluatorKey) && type == other.type && id == other.id
    end
  end
end

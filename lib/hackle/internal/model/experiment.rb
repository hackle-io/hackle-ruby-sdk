# frozen_string_literal: true

module Hackle
  class Experiment
    # @return [Integer]
    attr_reader :id

    # @return [Integer]
    attr_reader :key

    # @return [String, nil]
    attr_reader :name

    # @return [ExperimentType]
    attr_reader :type

    # @return [String]
    attr_reader :identifier_type

    # @return [ExperimentStatus]
    attr_reader :status

    # @return [Integer]
    attr_reader :version

    # @return [Integer]
    attr_reader :execution_version

    # @return [Array<Variation>]
    attr_reader :variations

    # @return [Hash{String => Integer}]
    attr_reader :user_overrides

    # @return [Array<TargetRule>]
    attr_reader :segment_overrides

    # @return [Array<Target>]
    attr_reader :target_audiences

    # @return [Array<TargetRule>]
    attr_reader :target_rules

    # @return [Action]
    attr_reader :default_rule

    # @return [Integer, nil]
    attr_reader :container_id

    # @return [Integer, nil]
    attr_reader :winner_variation_id

    # @param [Integer] id
    # @param [Integer] key
    # @param [String, nil] name
    # @param [ExperimentType] type
    # @param [String] identifier_type
    # @param [ExperimentStatus] status
    # @param [Integer] version
    # @param [Integer] execution_version
    # @param [Array<Variation>] variations
    # @param [Hash{String => Integer}] user_overrides
    # @param [Array<TargetRule>] segment_overrides
    # @param [Array<Target>] target_audiences
    # @param [Array<TargetRule>] target_rules
    # @param [Action] default_rule
    # @param [Integer, nil] container_id
    # @param [Integer, nil] winner_variation_id
    def initialize(
      id:,
      key:,
      name:,
      type:,
      identifier_type:,
      status:,
      version:,
      execution_version:,
      variations:,
      user_overrides:,
      segment_overrides:,
      target_audiences:,
      target_rules:,
      default_rule:,
      container_id:,
      winner_variation_id:
    )
      @id = id
      @key = key
      @name = name
      @type = type
      @identifier_type = identifier_type
      @status = status
      @version = version
      @execution_version = execution_version
      @variations = variations
      @user_overrides = user_overrides
      @segment_overrides = segment_overrides
      @target_audiences = target_audiences
      @target_rules = target_rules
      @default_rule = default_rule
      @container_id = container_id
      @winner_variation_id = winner_variation_id
    end

    # @param id [Integer]
    # @return [Hackle::Variation, nil]
    def get_variation_or_nil_by_id(id)
      variations.find { |v| v.id == id }
    end

    # @param key [String]
    # @return [Hackle::Variation, nil]
    def get_variation_or_nil_by_key(key)
      variations.find { |v| v.key == key }
    end

    # @return [Hackle::Variation, nil]
    def winner_variation_or_nil
      get_variation_or_nil_by_id(winner_variation_id) unless winner_variation_id.nil?
    end
  end

  class ExperimentType
    # @!attribute [r] name
    #   @return [String]
    attr_reader :name

    # @param name [String]
    def initialize(name)
      @name = name
    end

    def to_s
      name
    end

    AB_TEST = new('AB_TEST')
    FEATURE_FLAG = new('FEATURE_FLAG')

    @types = {
      'AB_TEST' => AB_TEST,
      'FEATURE_FLAG' => FEATURE_FLAG
    }.freeze

    # @param name [String]
    # @return [ExperimentType, nil]
    def self.from_or_nil(name)
      @types[name.upcase]
    end

    # @return [Array<ExperimentType>]
    def self.values
      @types.values
    end
  end

  class ExperimentStatus
    # @!attribute [r] name
    #   @return [String]
    attr_reader :name

    # @param name [String]
    def initialize(name)
      @name = name
    end

    def to_s
      name
    end

    DRAFT = new('DRAFT')
    RUNNING = new('RUNNING')
    PAUSED = new('PAUSED')
    COMPLETED = new('COMPLETED')

    @types = {
      'READY' => DRAFT,
      'RUNNING' => RUNNING,
      'PAUSED' => PAUSED,
      'STOPPED' => COMPLETED
    }.freeze

    # @param name [String]
    # @return [ExperimentStatus, nil]
    def self.from_or_nil(name)
      @types[name.upcase]
    end

    # @return [Array<ExperimentStatus>]
    def self.values
      @types.values
    end
  end
end

# frozen_string_literal: true

module Hackle
  class Target
    # @!attribute [r] conditions
    #   @return [Array<TargetCondition>]
    attr_reader :conditions

    # @param conditions [Array<TargetCondition>]
    def initialize(conditions:)
      @conditions = conditions
    end
  end

  class TargetCondition
    # @!attribute [r] key
    #   @return [TargetKey]
    # @!attribute [r] match
    #   @return [TargetMatch]
    attr_reader :key, :match

    def initialize(key:, match:)
      @key = key
      @match = match
    end
  end

  class TargetKey
    # @!attribute [r] type
    #   @return [TargetKeyType]
    # @!attribute [r] name
    #   @return [String]
    attr_reader :type, :name

    # @param type [TargetKeyType]
    # @param name [String]
    def initialize(type:, name:)
      @type = type
      @name = name
    end
  end

  class TargetMatch

    # @!attribute [r] type
    #   @return [TargetMatchType]
    # @!attribute [r] operator
    #   @return [TargetOperator]
    # @!attribute [r] value_type
    #   @return [ValueType]
    # @!attribute [r] values
    #   @return [Array<Object>]
    attr_reader :type, :operator, :value_type, :values

    # @param type [TargetMatchType]
    # @param operator [TargetOperator]
    # @param value_type [ValueType]
    # @param values [Array<Object>]
    def initialize(type:, operator:, value_type:, values:)
      @type = type
      @operator = operator
      @value_type = value_type
      @values = values
    end

  end

  class TargetKeyType
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

    USER_ID = new('USER_ID')
    USER_PROPERTY = new('USER_PROPERTY')
    HACKLE_PROPERTY = new('HACKLE_PROPERTY')
    SEGMENT = new('SEGMENT')
    AB_TEST = new('AB_TEST')
    FEATURE_FLAG = new('FEATURE_FLAG')

    @types = {
      'USER_ID' => USER_ID,
      'USER_PROPERTY' => USER_PROPERTY,
      'HACKLE_PROPERTY' => HACKLE_PROPERTY,
      'SEGMENT' => SEGMENT,
      'AB_TEST' => AB_TEST,
      'FEATURE_FLAG' => FEATURE_FLAG
    }.freeze

    # @param name [String]
    # @return [TargetKeyType, nil]
    def self.from_or_nil(name)
      @types[name.upcase]
    end

    # @return [Array<TargetKeyType>]
    def self.values
      @types.values
    end
  end

  class TargetMatchType
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

    MATCH = new('MATCH')
    NOT_MATCH = new('NOT MATCH')

    @types = {
      'MATCH' => MATCH,
      'NOT_MATCH' => NOT_MATCH
    }

    # @param name [String]
    # @return [TargetMatchType, nil]
    def self.from_or_nil(name)
      @types[name.upcase]
    end

    # @return [Array<TargetMatchType>]
    def self.values
      @types.values
    end

    # @param type [TargetMatchType]
    # @param matches [boolean]
    # @return [boolean]
    def self.matches(type, matches)
      case type
      when MATCH
        matches
      when NOT_MATCH
        !matches
      else
        raise ArgumentError, "Unsupported type: #{type}"
      end
    end
  end

  class TargetOperator
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

    IN = new('IN')
    CONTAINS = new('CONTAINS')
    STARTS_WITH = new('STARTS_WITH')
    ENDS_WITH = new('ENDS_WITH')
    GT = new('GT')
    GTE = new('GTE')
    LT = new('LT')
    LTE = new('LTE')

    @types = {
      'IN' => IN,
      'CONTAINS' => CONTAINS,
      'STARTS_WITH' => STARTS_WITH,
      'ENDS_WITH' => ENDS_WITH,
      'GT' => GT,
      'GTE' => GTE,
      'LT' => LT,
      'LTE' => LTE
    }.freeze

    # @param name [String]
    # @return [TargetOperator, nil]
    def self.from_or_nil(name)
      @types[name.upcase]
    end

    # @return [Array<TargetOperator>]
    def self.values
      @types.values
    end
  end
end

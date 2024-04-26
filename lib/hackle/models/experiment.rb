module Hackle
  class Experiment

    # @!attribute [r] id
    #   @return [Integer]
    # @!attribute [r] key
    #   @return [Integer]
    attr_reader :id, :key

    # @param id [Integer]
    # @param key [Integer]
    def initialize(id:, key:)
      @id = id
      @key = key
    end

    class Running < Experiment

      # @!attribute [r] bucket
      #   @return [Bucket]
      attr_reader :bucket

      # @param id [Integer]
      # @param key [Integer]
      # @param bucket [Bucket]
      # @param variations [Hash{String => Variation}]
      # @param overrides [Hash{String => Integer}]
      def initialize(id:, key:, bucket:, variations:, overrides:)
        super(id: id, key: key)
        @bucket = bucket

        # @type [Hash{String => Variation}]
        @variations = variations

        # @type [Hash{String => Integer}]
        @overrides = overrides
      end

      # @param variation_id [Integer]
      # @return [Variation, nil]
      def get_variation(variation_id:)
        @variations[variation_id]
      end

      # @param user [User]
      # @return [Variation, nil]
      def get_overridden_variation(user:)
        overridden_variation_id = @overrides[user.id]
        return nil if overridden_variation_id.nil?
        get_variation(variation_id: overridden_variation_id)
      end
    end

    class Completed < Experiment

      # @!attribute [r] winner_variation_key
      #  @return [String]
      attr_reader :winner_variation_key

      # @param id [Integer]
      # @param key [Integer]
      # @param winner_variation_key [String]
      def initialize(id:, key:, winner_variation_key:)
        super(id: id, key: key)
        @winner_variation_key = winner_variation_key
      end
    end
  end
end

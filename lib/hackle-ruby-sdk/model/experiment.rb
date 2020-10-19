module Hackle
  class Experiment
    attr_reader :id, :key

    def initialize(id, key)
      @id = id
      @key = key
    end

    class Running < Experiment
      attr_reader :bucket

      def initialize(id, key, bucket, variations, user_overrides)
        super(id, key)
        @bucket = bucket
        @variations = variations
        @user_overrides = user_overrides
      end

      def get_variation(variation_id)
        @variations[variation_id]
      end

      def get_overridden_variation(user_id)
        variation_id = @user_overrides[user_id]
        get_variation(variation_id)
      end
    end

    class Completed < Experiment
      attr_reader :winner_variation_key

      def initialize(id, key, winner_variation_key)
        super(id, key)
        @winner_variation_key = winner_variation_key
      end
    end
  end
end

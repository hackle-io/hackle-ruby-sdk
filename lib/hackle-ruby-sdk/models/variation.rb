module Hackle
  class Variation
    attr_reader :id, :key, :dropped

    def initialize(id, key, dropped)
      @id = id
      @key = key
      @dropped = dropped
    end
  end
end

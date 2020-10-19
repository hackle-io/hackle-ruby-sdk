module Hackle
  class EventType
    attr_reader :id, :key

    def initialize(id, key)
      @id = id
      @key = key
    end
  end
end

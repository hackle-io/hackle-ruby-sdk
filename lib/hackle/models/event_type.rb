module Hackle
  class EventType
    attr_reader :id, :key

    def initialize(id:, key:)
      @id = id
      @key = key
    end

    def self.undefined(key:)
      EventType.new(id: 0, key: key)
    end
  end
end

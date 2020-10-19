# frozen_string_literal: true

module Hackle
  VERSION = '0.0.1'
  SDK_NAME = 'ruby-sdk'

  class SdkInfo
    attr_reader :key, :name, :version
    def initialize(key)
      @key = key
      @name = SDK_NAME
      @version = VERSION
    end
  end
end

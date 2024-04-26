# frozen_string_literal: true

module Hackle
  VERSION = '1.0.0'
  SDK_NAME = 'ruby-sdk'

  class SdkInfo
    attr_reader :key, :name, :version
    def initialize(key:)
      @key = key
      @name = SDK_NAME
      @version = VERSION
    end
  end
end

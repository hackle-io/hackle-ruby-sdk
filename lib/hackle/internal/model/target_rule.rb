# frozen_string_literal: true

module Hackle
  class TargetRule

    # @!attribute [r] target
    #   @return [Target]
    # @!attribute [r] action
    #   @return [Action]
    attr_accessor :target, :action

    # @param target [Target]
    # @param action [Action]
    def initialize(target:, action:)
      @target = target
      @action = action
    end
  end
end

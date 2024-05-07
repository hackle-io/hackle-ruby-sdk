# frozen_string_literal: true

require 'hackle/user'
require 'hackle/internal/user/hackle_user'

module Hackle
  class HackleUserResolver
    # @param user [User]
    # @return [HackleUser]
    def resolve_or_nil(user)
      return nil if user.nil?
      return nil unless user.is_a?(User)

      builder = HackleUser.builder
      builder.identifiers(user.identifiers)
      builder.identifier('$id', user.id) unless user.id.nil?
      builder.identifier('$deviceId', user.device_id) unless user.device_id.nil?
      builder.identifier('$userId', user.user_id) unless user.user_id.nil?
      builder.properties(user.properties)
      hackle_user = builder.build

      return nil if hackle_user.identifiers.empty?

      hackle_user
    end
  end
end

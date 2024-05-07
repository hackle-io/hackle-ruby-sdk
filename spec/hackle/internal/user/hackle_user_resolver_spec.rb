# frozen_string_literal: true

require 'rspec'
require 'models'
require 'hackle/internal/user/hackle_user_resolver'

module Hackle
  RSpec.describe HackleUserResolver do

    it 'empty' do
      actual = HackleUserResolver.new.resolve_or_nil(User.builder.build)
      expect(actual).to be_nil
    end

    it 'resolve' do
      user = User.builder
                 .id('id')
                 .user_id('user_id')
                 .device_id('device_id')
                 .identifiers(
                   {
                     '$id' => '!',
                     '$userId' => '!',
                     '$deviceId' => '!',
                     'custom_id' => 'custom_value'
                   }
                 )
                 .properties(
                   {
                     'age' => 42,
                     'grade' => 'GOLD',
                     'arr' => [1, 2, 3]
                   }
                 )
                 .build

      actual = HackleUserResolver.new.resolve_or_nil(user)
      expect(actual).to eq(HackleUser.new(
        identifiers: {
          '$id' => 'id',
          '$userId' => 'user_id',
          '$deviceId' => 'device_id',
          'custom_id' => 'custom_value'
        },
        properties: {
          'age' => 42,
          'grade' => 'GOLD',
          'arr' => [1, 2, 3]
        }
      ))
    end
  end
end

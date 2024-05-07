# frozen_string_literal: true

require 'rspec'
require 'hackle/user'

module Hackle
  RSpec.describe User do
    it 'user build' do
      user = User.builder
                 .id('id')
                 .device_id('device_id')
                 .user_id('user_id')
                 .identifier('id_1', 'v1')
                 .identifiers({ 'id_2' => 'v2' })
                 .property('int_key', 42)
                 .property('double_key', 42.42)
                 .property('boolean_key', true)
                 .property('string_key', 'abc 123')
                 .property('nil', nil)
                 .properties({ 'k1' => 'v1', 'k2' => 2 })
                 .build

      expect(user).to eq(User.new(
        id: 'id',
        user_id: 'user_id',
        device_id: 'device_id',
        identifiers: {
          'id_1' => 'v1',
          'id_2' => 'v2'
        },
        properties: {
          'int_key' => 42,
          'double_key' => 42.42,
          'boolean_key' => true,
          'string_key' => 'abc 123',
          'k1' => 'v1',
          'k2' => 2
        }
      ))
      expect(user.to_s).to include('Hackle::User')

    end

    it 'max property count is 128' do
      builder = User.builder
      128.times do |i|
        builder.property(i.to_s, i)
      end
      user = builder.build
      expect(user.properties.length).to eq(128)
    end

    it 'max property key length is 128' do
      key128 = 'a' * 128
      key129 = 'a' * 129

      user = User.builder.property(key128, 128).property(key129, 129).build

      expect(user.properties).to have_key(key128)
      expect(user.properties).not_to have_key(key129)
    end

    it 'max string property value is 1024' do
      v1024 = 'a' * 1024
      v1025 = 'a' * 1025

      user = User.builder.property('1024', v1024).property('1025', v1025).build

      expect(user.properties).to have_key('1024')
      expect(user.properties).not_to have_key('1025')
    end
  end
end

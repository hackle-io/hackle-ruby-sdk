# frozen_string_literal: true

require 'rspec'
require 'hackle/internal/properties/properties_builder'

module Hackle
  RSpec.describe PropertiesBuilder do

    it 'raw value valid build' do
      expect(PropertiesBuilder.new.add('key1', 1).build).to eq({ 'key1' => 1 })
      expect(PropertiesBuilder.new.add('key1', '1').build).to eq({ 'key1' => '1' })
      expect(PropertiesBuilder.new.add('key1', true).build).to eq({ 'key1' => true })
      expect(PropertiesBuilder.new.add('key1', false).build).to eq({ 'key1' => false })
    end

    it 'raw invalid value' do
      expect(PropertiesBuilder.new.add('key1', {}).build).to eq({})
    end

    it 'array value' do
      expect(PropertiesBuilder.new.add('key1', [1, 2, 3]).build).to eq({ 'key1' => [1, 2, 3] })
      expect(PropertiesBuilder.new.add('key1', ['1', '2', '3']).build).to eq({ 'key1' => ['1', '2', '3'] })
      expect(PropertiesBuilder.new.add('key1', ['1', 2, '3']).build).to eq({ 'key1' => ['1', 2, '3'] })
      expect(PropertiesBuilder.new.add('key1', [1, 2, nil, 3]).build).to eq({ 'key1' => [1, 2, 3] })
      expect(PropertiesBuilder.new.add('key1', [true, false]).build).to eq({ 'key1' => [] })
      expect(PropertiesBuilder.new.add('key1', ['a' * 1025]).build).to eq({ 'key1' => [] })
    end

    it 'max property size is 128' do
      builder = PropertiesBuilder.new
      128.times { |i| builder.add(i.to_s, i) }
      builder.add('key', 42)
      expect(builder.build.length).to eq(128)
      expect(builder.build).not_to have_key('key')
    end

    it 'max key length is 128' do
      builder = PropertiesBuilder.new.add('a' * 128, 128)
      expect(builder.build.length).to eq(1)

      builder.add('a' * 129, 129)
      expect(builder.build.length).to eq(1)
    end

    it 'invalid key' do
      expect(PropertiesBuilder.new.add(nil, 1).build).to eq({})
      expect(PropertiesBuilder.new.add(1, 1).build).to eq({})
      expect(PropertiesBuilder.new.add('', 1).build).to eq({})
    end

    it 'add all' do
      properties = {
        'k1' => 'v1',
        'k2' => 2,
        'k3' => true,
        'k4' => false,
        'k5' => [1, 2, 3],
        'k6' => ['1', '2', '3'],
        'k7' => nil
      }
      expect(PropertiesBuilder.new.add_all(properties).build.length).to eq(6)
    end

    it "add system properties" do
      properties = PropertiesBuilder.new.add("$set", { "age" => 42 }).add("set", { "age" => 42 }).build
      expect(properties).to eq({ "$set" => { "age" => 42 } })
    end
  end
end

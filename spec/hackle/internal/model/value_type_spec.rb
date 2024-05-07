# frozen_string_literal: true

require 'rspec'
require 'hackle/internal/model/value_type'

module Hackle
  RSpec.describe ValueType do
    it 'from_or_nil' do
      expect(ValueType.from_or_nil('NULL')).to eq(ValueType::NULL)
      expect(ValueType.from_or_nil('UNKNOWN')).to eq(ValueType::UNKNOWN)
      expect(ValueType.from_or_nil('STRING')).to eq(ValueType::STRING)
      expect(ValueType.from_or_nil('NUMBER')).to eq(ValueType::NUMBER)
      expect(ValueType.from_or_nil('BOOLEAN')).to eq(ValueType::BOOLEAN)
      expect(ValueType.from_or_nil('VERSION')).to eq(ValueType::VERSION)
      expect(ValueType.from_or_nil('JSON')).to eq(ValueType::JSON)
      expect(ValueType.from_or_nil('INVALID')).to be_nil
    end

    it 'values' do
      expect(ValueType.values).to eq([
                                       ValueType::NULL,
                                       ValueType::UNKNOWN,
                                       ValueType::STRING,
                                       ValueType::NUMBER,
                                       ValueType::BOOLEAN,
                                       ValueType::VERSION,
                                       ValueType::JSON
                                     ])
    end

    it 'check' do
      expect(ValueType.string?(nil)).to eq(false)
      expect(ValueType.string?(1)).to eq(false)
      expect(ValueType.string?(0)).to eq(false)
      expect(ValueType.string?(-1)).to eq(false)
      expect(ValueType.string?(true)).to eq(false)
      expect(ValueType.string?(false)).to eq(false)
      expect(ValueType.string?('')).to eq(true)
      expect(ValueType.string?('42')).to eq(true)

      expect(ValueType.empty_string?(nil)).to eq(false)
      expect(ValueType.empty_string?(1)).to eq(false)
      expect(ValueType.empty_string?(0)).to eq(false)
      expect(ValueType.empty_string?(-1)).to eq(false)
      expect(ValueType.empty_string?(true)).to eq(false)
      expect(ValueType.empty_string?(false)).to eq(false)
      expect(ValueType.empty_string?('42')).to eq(false)
      expect(ValueType.empty_string?('')).to eq(true)

      expect(ValueType.not_empty_string?(nil)).to eq(false)
      expect(ValueType.not_empty_string?(1)).to eq(false)
      expect(ValueType.not_empty_string?(0)).to eq(false)
      expect(ValueType.not_empty_string?(-1)).to eq(false)
      expect(ValueType.not_empty_string?(true)).to eq(false)
      expect(ValueType.not_empty_string?(false)).to eq(false)
      expect(ValueType.not_empty_string?('')).to eq(false)
      expect(ValueType.not_empty_string?('42')).to eq(true)

      expect(ValueType.number?(nil)).to eq(false)
      expect(ValueType.number?(1)).to eq(true)
      expect(ValueType.number?(1.0)).to eq(true)
      expect(ValueType.number?(1.1)).to eq(true)
      expect(ValueType.number?(0)).to eq(true)
      expect(ValueType.number?(-1)).to eq(true)
      expect(ValueType.number?(true)).to eq(false)
      expect(ValueType.number?(false)).to eq(false)
      expect(ValueType.number?('')).to eq(false)
      expect(ValueType.number?('42')).to eq(false)

      expect(ValueType.boolean?(nil)).to eq(false)
      expect(ValueType.boolean?(1)).to eq(false)
      expect(ValueType.boolean?(1.0)).to eq(false)
      expect(ValueType.boolean?(1.1)).to eq(false)
      expect(ValueType.boolean?(0)).to eq(false)
      expect(ValueType.boolean?(-1)).to eq(false)
      expect(ValueType.boolean?(true)).to eq(true)
      expect(ValueType.boolean?(false)).to eq(true)
      expect(ValueType.boolean?('')).to eq(false)
      expect(ValueType.boolean?('true')).to eq(false)
      expect(ValueType.boolean?('false')).to eq(false)
    end
  end
end

# frozen_string_literal: true

require 'rspec'
require 'hackle/internal/config/parameter_config'

module Hackle
  describe ParameterConfig do

    context 'config' do
      config = ParameterConfig.new(
        {
          'string_key' => 'string_value',
          'string_empty' => '',
          'int_key' => 42,
          'zero_int_key' => 0,
          'negative_int_key' => -1,
          'float_key' => 0.42,
          'true_boolean_key' => true,
          'false_boolean_key' => false
        }
      )
      it 'get' do
        expect(config.get("string_key")).to eq("string_value")
        expect(config.get("string_key", "!!")).to eq("string_value")
        expect(config.get("string_empty", "!!")).to eq("")
        expect(config.get("int_key", 99)).to eq(42)
        expect(config.get("zero_int_key", 99)).to eq(0)
        expect(config.get("negative_int_key", 99)).to eq(-1)
        expect(config.get("float_key", 99)).to eq(0.42)
        expect(config.get("true_boolean_key", false)).to eq(true)
        expect(config.get("false_boolean_key", true)).to eq(false)

        expect(config.get("string_default", "!!")).to eq("!!")
        expect(config.get("number_default", 42)).to eq(42)
        expect(config.get("boolean_default", true)).to eq(true)

        expect(config.to_s).to include('Hackle::ParameterConfig')
      end

      it 'type' do
        expect(config.get("string_key", 42)).to eq(42)
        expect(config.get("int_key", "!!")).to eq("!!")
        expect(config.get("true_boolean_key", "true")).to eq("true")
      end

      it 'nil' do
        expect(config.get("nil")).to be_nil
        expect(config.get("nil", { 'a' => 'b' })).to eq({ 'a' => 'b' })
      end
    end
  end
end

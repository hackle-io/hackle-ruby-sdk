# frozen_string_literal: true

require 'rspec'
require 'hackle/internal/identifiers/identifier_builder'

module Hackle
  RSpec.describe IdentifiersBuilder do
    context 'validations' do
      it 'ensures max identifier type length is 128' do
        builder = IdentifiersBuilder.new
        builder.add("a" * 128, "128")
        builder.add("a" * 129, "129")
        expect(builder.build).to eq({ "a" * 128 => "128" })
      end

      it 'ensures max identifier value length is 512' do
        builder = IdentifiersBuilder.new
        builder.add("512", "a" * 512)
        builder.add("513", "a" * 513)
        expect(builder.build).to eq({ "512" => "a" * 512 })
      end

      it 'rejects empty identifier type' do
        builder = IdentifiersBuilder.new
        builder.add("", "a")
        builder.add("", nil)
        expect(builder.build).to eq({})
      end

      it 'rejects empty identifier value' do
        builder = IdentifiersBuilder.new
        builder.add("a", "")
        expect(builder.build).to eq({})
      end

      it 'correctly adds all identifiers' do
        builder = IdentifiersBuilder.new.add_all({ "a" => "b", "c" => "d" })
        expect(builder.build).to eq({ "a" => "b", "c" => "d" })
      end
    end
  end
end

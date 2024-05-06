# frozen_string_literal: true

require 'rspec'
require 'hackle/internal/evaluation/bucketer/bucketer'
require 'hackle/internal/model/bucket'

module Hackle
  describe Bucketer do

    it 'bucketing' do
      hasher = double
      allow(hasher).to receive(:hash).with(anything, anything).and_return(42)
      sut = Bucketer.new(hasher: hasher)

      expect(sut.bucketing(Bucket.new(id: 1, seed: 320, slot_size: 10_000, slots: []), '42')).to be_nil

      slot = Slot.new(start_inclusive: 0, end_exclusive: 42, variation_id: 420)
      bucket = Bucket.new(id: 1, seed: 320, slot_size: 10_000, slots: [slot])
      expect(sut.bucketing(bucket, '42')).to be_nil

      slot = Slot.new(start_inclusive: 0, end_exclusive: 43, variation_id: 420)
      bucket = Bucket.new(id: 1, seed: 320, slot_size: 10_000, slots: [slot])
      actual = sut.bucketing(bucket, '42')
      expect(actual).not_to be_nil
      expect(actual).to eq(slot)
    end

    it 'calculate_slot_number' do
      def _test(filename)
        sut = Bucketer.new(hasher: Hasher.new)
        File.foreach(filename) do |line|
          row = line.split(',')
          seed = row[0].to_i
          slot_size = row[1].to_i
          value = row[2]
          slot_number = row[3].to_i

          expect(sut.calculate_slot_number(seed: seed, slot_size: slot_size, value: value)).to eq(slot_number)
        end
      end

      _test('spec/data/bucketing_all.csv')
      _test('spec/data/bucketing_alphabetic.csv')
      _test('spec/data/bucketing_alphanumeric.csv')
      _test('spec/data/bucketing_numeric.csv')
      _test('spec/data/bucketing_uuid.csv')
    end
  end

  describe Hasher do
    it 'hash' do
      def _test(filename)
        sut = Hasher.new
        File.foreach(filename) do |line|
          row = line.split(',')
          data = row[0]
          seed = row[1].to_i
          hash_value = row[2].to_i

          expect(sut.hash(data, seed)).to eq(hash_value)
        end
      end

      _test('spec/data/murmur_all.csv')
      _test('spec/data/murmur_alphabetic.csv')
      _test('spec/data/murmur_alphanumeric.csv')
      _test('spec/data/murmur_numeric.csv')
      _test('spec/data/murmur_uuid.csv')
    end
  end
end

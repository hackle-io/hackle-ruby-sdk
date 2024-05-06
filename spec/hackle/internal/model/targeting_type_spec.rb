# frozen_string_literal: true

require 'rspec'
require 'hackle/internal/model/targeting'
require 'hackle/internal/model/target'

module Hackle
  describe TargetingType do
    it 'IDENTIFIER' do
      targeting_type = TargetingType::IDENTIFIER
      expect(targeting_type.supports?(TargetKeyType::USER_ID)).to eq(false)
      expect(targeting_type.supports?(TargetKeyType::USER_PROPERTY)).to eq(false)
      expect(targeting_type.supports?(TargetKeyType::HACKLE_PROPERTY)).to eq(false)
      expect(targeting_type.supports?(TargetKeyType::SEGMENT)).to eq(true)
      expect(targeting_type.supports?(TargetKeyType::AB_TEST)).to eq(false)
      expect(targeting_type.supports?(TargetKeyType::FEATURE_FLAG)).to eq(false)
    end

    it 'PROPERTY' do
      targeting_type = TargetingType::PROPERTY
      expect(targeting_type.supports?(TargetKeyType::USER_ID)).to eq(false)
      expect(targeting_type.supports?(TargetKeyType::USER_PROPERTY)).to eq(true)
      expect(targeting_type.supports?(TargetKeyType::HACKLE_PROPERTY)).to eq(true)
      expect(targeting_type.supports?(TargetKeyType::SEGMENT)).to eq(true)
      expect(targeting_type.supports?(TargetKeyType::AB_TEST)).to eq(true)
      expect(targeting_type.supports?(TargetKeyType::FEATURE_FLAG)).to eq(true)
    end

    it 'SEGMENT' do
      targeting_type = TargetingType::SEGMENT
      expect(targeting_type.supports?(TargetKeyType::USER_ID)).to eq(true)
      expect(targeting_type.supports?(TargetKeyType::USER_PROPERTY)).to eq(true)
      expect(targeting_type.supports?(TargetKeyType::HACKLE_PROPERTY)).to eq(true)
      expect(targeting_type.supports?(TargetKeyType::SEGMENT)).to eq(false)
      expect(targeting_type.supports?(TargetKeyType::AB_TEST)).to eq(false)
      expect(targeting_type.supports?(TargetKeyType::FEATURE_FLAG)).to eq(false)
    end
  end
end

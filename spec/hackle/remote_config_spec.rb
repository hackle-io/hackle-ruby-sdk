# frozen_string_literal: true

require 'rspec'
require 'models'
require 'hackle/remote_config'

module Hackle
  RSpec.describe RemoteConfig do

    before do
      @user = User.builder.build
      @user_resolver = double
      @core = double
      @sut = RemoteConfig.new(user: @user, user_resolver: @user_resolver, core: @core)
    end
    it 'when cannot resolve user then return default value' do
      allow(@user_resolver).to receive(:resolve_or_nil).and_return(nil)

      actual = @sut.get('key', 'default')

      expect(actual).to eq('default')
    end

    it 'when key is nil then return default value' do
      allow(@user_resolver).to receive(:resolve_or_nil).and_return(double)

      actual = @sut.get(nil, 'default')

      expect(actual).to eq('default')
    end

    it 'when error raised on evaluate then return default value' do
      allow(@user_resolver).to receive(:resolve_or_nil).and_return(double)
      allow(@core).to receive(:remote_config).and_raise(ArgumentError)

      actual = @sut.get('key', 'default')

      expect(actual).to eq('default')
    end

    it 'decision' do
      hackle_user = HackleUser.builder.build
      allow(@user_resolver).to receive(:resolve_or_nil).and_return(hackle_user)
      allow(@core).to receive(:remote_config).and_return(RemoteConfigDecision.new('decision', 'reason'))

      actual = @sut.get('key', 'default')

      expect(actual).to eq('decision')
      expect(@core).to have_received(:remote_config).with('key', hackle_user, anything, 'default').exactly(1).times
    end

    describe 'type' do

      it 'null' do
        allow(@user_resolver).to receive(:resolve_or_nil).and_return(double)
        allow(@core).to receive(:remote_config).and_return(RemoteConfigDecision.new('decision', 'reason'))

        actual = @sut.get('key', nil)

        expect(actual).to eq('decision')
        expect(@core).to have_received(:remote_config).with('key', anything, ValueType::NULL, nil).exactly(1).times
      end

      it 'string' do
        allow(@user_resolver).to receive(:resolve_or_nil).and_return(double)
        allow(@core).to receive(:remote_config).and_return(RemoteConfigDecision.new('decision', 'reason'))

        actual = @sut.get('key', 'string')

        expect(actual).to eq('decision')
        expect(@core).to have_received(:remote_config).with('key', anything, ValueType::STRING, 'string').exactly(1).times
      end

      it 'number' do
        allow(@user_resolver).to receive(:resolve_or_nil).and_return(double)
        allow(@core).to receive(:remote_config).and_return(RemoteConfigDecision.new('decision', 'reason'))

        actual = @sut.get('key', 42)

        expect(actual).to eq('decision')
        expect(@core).to have_received(:remote_config).with('key', anything, ValueType::NUMBER, 42).exactly(1).times
      end

      it 'boolean' do
        allow(@user_resolver).to receive(:resolve_or_nil).and_return(double)
        allow(@core).to receive(:remote_config).and_return(RemoteConfigDecision.new('decision', 'reason'))

        actual = @sut.get('key', true)

        expect(actual).to eq('decision')
        expect(@core).to have_received(:remote_config).with('key', anything, ValueType::BOOLEAN, true).exactly(1).times
      end

      it 'unknown' do
        allow(@user_resolver).to receive(:resolve_or_nil).and_return(double)
        allow(@core).to receive(:remote_config).and_return(RemoteConfigDecision.new('decision', 'reason'))

        actual = @sut.get('key', [1, 2, 3])

        expect(actual).to eq('decision')
        expect(@core).to have_received(:remote_config).with('key', anything, ValueType::UNKNOWN, [1, 2, 3]).exactly(1).times
      end
    end
  end
end

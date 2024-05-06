# frozen_string_literal: true

require 'rspec'
require 'models'
require 'hackle/event'

module Hackle
  describe Event do
    it 'build event' do
      event = Event.builder('purchase')
                   .value(42)
                   .property('k1', 'v1')
                   .property('k2', 2)
                   .property('arr', [42, 43])
                   .properties({ 'k3' => true })
                   .build

      expect(event.valid?).to eq(true)
      expect(event).to eq(Event.new(
        key: 'purchase',
        value: 42,
        properties: {
          'k1' => 'v1',
          'k2' => 2,
          'arr' => [42, 43],
          'k3' => true
        }
      ))

      expect(event.to_s).to include('Hackle::Event')
    end

    it 'invalid' do
      expect(Event.builder(nil).build.error_or_nil).to include('Invalid event key')
      expect(Event.builder('k').value('42').build.error_or_nil).to include('Invalid event value')
      expect(Event.new(key: 'k', value: 42, properties: '42').error_or_nil).to include('Invalid event properties')
    end
  end
end

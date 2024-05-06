# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'hackle-ruby-sdk'
  spec.version       = '2.0.0'
  spec.authors       = ['Hackle']
  spec.email         = ['platform@hackle.io']
  spec.summary       = 'Hackle Ruby SDK'
  spec.description   = 'Ruby SDK for Hackle A/B Tests, Feature Flags, Remote Configs, and Analytics.'
  spec.homepage      = 'https://github.com/hackle-io/hackle-ruby-sdk'
  spec.license       = 'Apache-2.0'

  spec.files         = Dir['lib/**/*']
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 1.28'

  spec.add_runtime_dependency 'concurrent-ruby', '~> 1.0'
  spec.add_runtime_dependency 'json', '~> 2.3'
  spec.add_runtime_dependency 'murmurhash3', '~> 0.1'
end

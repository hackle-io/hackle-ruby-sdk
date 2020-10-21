# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hackle-ruby-sdk/version'

Gem::Specification.new do |spec|
  spec.name          = 'hackle-ruby-sdk'
  spec.version       = Hackle::VERSION
  spec.authors       = ['Hackle']
  spec.email         = ['platform@hackle.io']
  spec.summary       = 'Hackle SDK for Ruby'
  spec.description   = 'Hackle SDK for Ruby'
  spec.homepage      = 'https://github.com/hackle-io/hackle-ruby-sdk'
  spec.license       = 'Apache-2.0'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(spec)/}) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.17'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '0.73.0'

  spec.add_runtime_dependency 'concurrent-ruby', '~> 1.0'
  spec.add_runtime_dependency 'json', '>= 1.8'
  spec.add_runtime_dependency 'murmurhash3', '~> 0.1'
end

# frozen_string_literal: true

require 'simplecov'
require 'simplecov-lcov'
require 'simplecov-cobertura'

SimpleCov.formatters = if ENV['COVERAGE']
                         SimpleCov::Formatter::MultiFormatter.new([
                                                                    SimpleCov::Formatter::CoberturaFormatter,
                                                                    SimpleCov::Formatter::LcovFormatter
                                                                  ])
                       else
                         SimpleCov::Formatter::MultiFormatter.new([
                                                                    SimpleCov::Formatter::HTMLFormatter
                                                                  ])
                       end
SimpleCov::Formatter::LcovFormatter.config.report_with_single_file = true
SimpleCov.start { add_filter '/spec/' } if ENV['COVERAGE']

require 'hackle'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

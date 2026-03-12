# Common spec helper

# Use test configiuration
ENV["APP_ENV"] = "test"

require "bundler/setup"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "simplecov"
require "simplecov-console"
require "vcr"

Dir[File.expand_path("support/**/*.rb", __dir__)].sort.each { |f| require f }

SimpleCov.start do
  add_filter "/spec/"
  add_filter "/regression-test/"

  add_group "Libs", "/lib/"
  add_group "Scripts", ->(src) { !src.filename.include?("/lib/") }

  track_files "lib/**/*.rb"
  track_files "*.rb"
end

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Console
  ]
)

# require "rspec"

# Load all support files
# Dir[File.expand_path('./support/**/*.rb', __dir__ || "spec/")].each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Make it stop on the first failure. Makes in this case
  # for quicker debugging
  config.fail_fast = !ENV["FAIL_FAST"].to_s.empty?

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

VCR.configure do |c|
  c.cassette_library_dir = "spec/cassettes"
  c.hook_into :webmock
  c.configure_rspec_metadata!
end

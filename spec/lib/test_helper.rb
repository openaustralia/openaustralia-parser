# Common spec helper

# Use test configiuration
ENV["APP_ENV"] = "test"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "bundler/setup"

require "test/unit"
require "simplecov"
require "simplecov-console"

SimpleCov.start do
  add_filter "/spec/"
  add_filter "/test/"
end

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Console
  ]
)

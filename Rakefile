# frozen_string_literal: true

require "rake"
require "rake/testtask"
require "rspec/core/rake_task"

task default: [:spec]

desc "Run all specs and tests"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = %w[spec/*_spec.rb test/test_*.rb]
end


# frozen_string_literal: true

require "fileutils"
require "rake"

require_relative "lib/configuration"

begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  task(:spec) { puts "rspec not available" }
end

task default: [:spec]

Dir["lib/tasks/*.rake"].each { |f| load f }

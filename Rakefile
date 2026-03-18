# frozen_string_literal: true

require "fileutils"
require "rake"
require "rspec/core/rake_task"

require_relative "lib/configuration"

task default: [:spec]

RSpec::Core::RakeTask.new(:spec)

Dir["lib/tasks/*.rake"].each { |f| load f }

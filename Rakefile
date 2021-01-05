require "rake"
require "rake/testtask"
require "rspec/core/rake_task"

task default: [:spec]

RSpec::Core::RakeTask.new do |t|
  t.ruby_opts = ["-rtest/unit"]
  t.pattern = ["spec/*_spec.rb", "test/test_*.rb"]
end

RSpec::Core::RakeTask.new(:spec_coverage) do |t|
  t.rcov = true
  t.rcov_opts = ["-x/Library/, -xspec"]
  t.ruby_opts = ["-rtest/unit"]
  t.pattern = ["spec/*_spec.rb", "test/test_*.rb"]
end

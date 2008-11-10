require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'spec/rake/spectask'

task :default => [:spec]

Spec::Rake::SpecTask.new do |t|
    t.warning = true
    t.ruby_opts = ['-rtest/unit']
    t.spec_files = FileList['spec/*_spec.rb', 'test/test_*.rb']
end

Spec::Rake::SpecTask.new(:spec_coverage) do |t|
    t.warning = true
    t.rcov = true
    t.rcov_opts = ["-x/Library/, -xspec"]
    t.ruby_opts = ['-rtest/unit']
    t.spec_files = FileList['spec/*_spec.rb', 'test/test_*.rb']
end

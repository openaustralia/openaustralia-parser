require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

task :default => [:test]

Rake::TestTask.new do |t|
    #t.libs << "test"
    t.test_files = FileList['tests/test*.rb']
    t.verbose = true
end
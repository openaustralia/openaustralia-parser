require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

task :default => [:test]

Rake::TestTask.new do |t|
    #t.libs << "test"
    t.test_files = FileList['tests/test*.rb']
    t.verbose = true
end

namespace :test do

  desc 'Measures test coverage'
  task :coverage do
    rm_f "coverage"
    rm_f "coverage.data"
    rcov = 'rcov --aggregate coverage.data --text-summary -Ilib -x/Library/'
    system("#{rcov} --html tests/test_*.rb")
    system("open coverage/index.html") if PLATFORM['darwin']
  end

end

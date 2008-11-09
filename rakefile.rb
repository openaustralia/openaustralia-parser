require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

task :default => [:test]

Rake::TestTask.new do |t|
    t.test_files = FileList['test/test*.rb']
    t.verbose = true
end

namespace :test do

  desc 'Measures test coverage'
  task :coverage do
    rm_f "coverage"
    system("rcov --text-summary -Ilib -x/Library/ test/test_*.rb")
    system("open coverage/index.html") if PLATFORM['darwin']
  end

end

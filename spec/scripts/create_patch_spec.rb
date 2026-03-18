# frozen_string_literal: true

# create_patch.rb is called by parse-speeches.rb interactively when a parse error occurs:
#   openaustralia-parser/parse-speeches.rb:102:
#     system "#{File.dirname(__FILE__)}/create_patch.rb #{house} #{date}"
# It is a developer tool, not part of the automated pipeline.

require_relative "../spec_helper"
require_relative "../../create_patch"

RSpec.describe "create_patch.rb" do
  let(:script) { File.expand_path("../../create_patch.rb", __dir__) }
  let(:debate_date) { "2026.03.04" }
  let(:output_files) { %w[original.xml patched.xml] }

  before do
    FileUtils.rm_rf output_files
  end

  after do
    FileUtils.rm_rf output_files
  end

  it "exits with error when wrong number of arguments" do
    exitstatus = nil
    output = capture_stdout_and_stderr { exitstatus = CreatePatch.new([]).run }
    puts "OUTPUT:\n#{output}\nEOF" if ENV["DEBUG"]
    puts output.inspect
    expect(exitstatus).to be_positive
  end

  it "exits with error for unknown house argument" do
    exitstatus = nil
    output = capture_stdout_and_stderr do
      exitstatus = CreatePatch.new(["badhouse", debate_date]).run
    end
    puts "OUTPUT:\n#{output}\nEOF" if ENV["DEBUG"]
    expect(exitstatus).to be_positive
    expect(output).to match(/reps|senate/i)
    output_files.each do |file|
      expect(File.size?(file)).to be_falsey
    end
  end

  it "accepts 'reps' as a valid house argument", :vcr do
    Dir.mktmpdir do |_dir|
      output = capture_stdout_and_stderr { CreatePatch.new(["reps", debate_date]).run }
      puts "OUTPUT:\n#{output}\nEOF" if ENV["DEBUG"]
      expect(output).not_to match(/Wrong number of parameters/)
      expect(output).not_to match(/Expected 'reps' or 'senate'/)
      output_files.each do |file|
        expect(File.size?(file)).to be_truthy
      end
    end
  end

  it "accepts 'senate' as a valid house argument", :vcr do
    Dir.mktmpdir do |_dir|
      output = capture_stdout_and_stderr { CreatePatch.new(["senate", debate_date]).run }
      puts "OUTPUT:\n#{output}\nEOF" if ENV["DEBUG"]
      expect(output).not_to match(/Wrong number of parameters/)
      expect(output).not_to match(/Expected 'reps' or 'senate'/)
      output_files.each do |file|
        expect(File.size?(file)).to be_truthy
      end
    end
  end
end

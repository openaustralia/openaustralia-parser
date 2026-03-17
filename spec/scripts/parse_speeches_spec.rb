# frozen_string_literal: true

# Called from:
#   twfy/scripts/morningupdate:42:
#     (cd ../../openaustralia-parser; bundle exec parse-speeches.rb previous-working-day)
#   regression-test/regression_test_parse_speeches.rb
#   README.md:121: Every weekday parse-speeches.rb gets run by cron
#
# --no-load flag already exists: skips perl xml2db.pl.
# Test date: 2025-02-04 - first sitting day of 2025, both chambers confirmed sitting.
#
# Expected output pattern (from regression tests):
#   spec/expected/parse-speeches/representatives_debates/2025-02-04.xml
#   spec/expected/parse-speeches/senate_debates/2025-02-04.xml
#
# If expected file is missing: copy output there and fail, prompting review.
# To refresh expected: delete the expected file and re-run.
#
# VCR cassette records Hansard HTTP responses.

require_relative "../spec_helper"

require "fileutils"
require "timecop"

require_relative "../../parse-speeches"

RSpec.describe "parse-speeches.rb" do

  describe "#parse_date" do
    let(:instance) { ParseSpeeches.new([]) }

    it "Parses date text" do
      expect(instance.parse_date("2011-12-31")).to eq Date.new(2011, 12, 31)
      expect(instance.parse_date("11 Mar 2026")).to eq Date.new(2026, 3, 11)
      expect(instance.parse_date("4.3.2021")).to eq Date.new(2021, 3, 4)
    end

    # Week of 2025-06-09 (Mon) .. 2025-06-15 (Sun)
    # Mon 09, Tue 10, Wed 11, Thu 12, Fri 13, Sat 14, Sun 15
    {
      "Mon" => [Date.new(2025, 6, 9), Date.new(2025, 6, 6)], # Mon -> Fri
      "Tue" => [Date.new(2025, 6, 10), Date.new(2025, 6, 9)], # Tue -> Mon
      "Wed" => [Date.new(2025, 6, 11), Date.new(2025, 6, 10)], # Wed -> Tue
      "Thu" => [Date.new(2025, 6, 12), Date.new(2025, 6, 11)], # Thu -> Wed
      "Fri" => [Date.new(2025, 6, 13), Date.new(2025, 6, 12)], # Fri -> Thu
      "Sat" => [Date.new(2025, 6, 14), Date.new(2025, 6, 13)], # Sat -> Fri
      "Sun" => [Date.new(2025, 6, 15), Date.new(2025, 6, 13)], # Sun -> Fri
    }.each do |day_name, (today, expected)|
      it "on #{day_name} returns the previous working day (#{expected.strftime('%a')})" do
        Timecop.freeze(today) do
          expect(instance.parse_date("previous-working-day")).to eq expected
        end
      end
    end
  end

  describe "integration tests", :integration, :vcr do

    let(:script) { File.expand_path("../../parse-speeches.rb", __dir__) }
    let(:test_date) { "2007-09-20" } # example from https://openaustralia.github.io/openaustralia/install-parser.html
    let(:output_dir) { File.expand_path("../../tmp/output/parse-speeches", __dir__) }
    let(:expected_dir) { File.expand_path("../expected/parse-speeches", __dir__) }

    let(:reps_output) { File.join(output_dir, "scrapedxml", "representatives_debates", "#{test_date}.xml") }
    let(:senate_output) { File.join(output_dir, "scrapedxml", "senate_debates", "#{test_date}.xml") }
    let(:reps_expected) { File.join(expected_dir, "representatives_debates", "#{test_date}.xml") }
    let(:senate_expected) { File.join(expected_dir, "senate_debates", "#{test_date}.xml") }

    before do
      FileUtils.mkdir_p(File.join(output_dir, "representatives_debates"))
      FileUtils.mkdir_p(File.join(output_dir, "senate_debates"))
      FileUtils.mkdir_p(File.join(expected_dir, "representatives_debates"))
      FileUtils.mkdir_p(File.join(expected_dir, "senate_debates"))
    end

    after { FileUtils.rm_rf(output_dir) }

    def run_script
      output = capture_stdout_and_stderr { ParseSpeeches.new(["--no-load", "--output-dir", output_dir, test_date]).run }
      puts "OUTPUT:\n#{output}\nEOF" if ENV["DEBUG"]
      output
    end

    it "loads without syntax errors" do
      output = `ruby -c #{script} 2>&1`
      expect($CHILD_STATUS.exitstatus).to eq(0)
      expect(output).to match(/Syntax OK/)
    end

    it "exits successfully with --no-load for test_date" do
      expect { run_script }.not_to raise_error
    end

    it "prints a message about the skipped perl command when --no-load is passed" do
      output = run_script
      expect(output).to match(/no.load.*disabled|not running|skipping/i)
      expect(output).to match(/xml2db\.pl/)
    end

    it "produces representatives XML matching expected" do
      run_script
      expect(File).to exist(reps_output), "Expected #{reps_output} to be created"

      unless File.exist?(reps_expected)
        FileUtils.cp(reps_output, reps_expected)
        fail "Expected file missing — please review #{reps_expected} and re-run"
      end

      expect(File.read(reps_output)).to eq(File.read(reps_expected))
    end

    it "produces senate XML matching expected" do
      run_script
      expect(File).to exist(senate_output), "Expected #{senate_output} to be created"

      unless File.exist?(senate_expected)
        FileUtils.cp(senate_output, senate_expected)
        fail "Expected file missing — please review #{senate_expected} and re-run"
      end

      expect(File.read(senate_output)).to eq(File.read(senate_expected))
    end
  end
end

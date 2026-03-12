# frozen_string_literal: true

# Called from:
#   Capfile:100: run "cd #{current_path}/openaustralia-parser && bundle exec parse-members.rb"
#   README.md:81: bundle exec ./parse-members.rb --test
#   regression-test/regression_test_parse_members.rb
#
# --no-load flag already exists: skips the perl xml2db.pl database load.
# No HTTP calls — reads from local CSV data files only.
# Output: people.xml, representatives.xml, senators.xml, ministers.xml, divisions.xml

require_relative "../spec_helper"
require "fileutils"

RSpec.describe "parse-members.rb", :integration do
  let(:script)       { File.expand_path("../../parse-members.rb", __dir__) }
  let(:expected_dir) { File.expand_path("../expected/parse-members", __dir__) }
  let(:output_dir)   { File.expand_path("../../tmp/output/parse-members", __dir__) }

  let(:output_files) do
    %w[people.xml representatives.xml senators.xml ministers.xml divisions.xml]
  end

  before { FileUtils.mkdir_p([expected_dir, output_dir]) }
  after  { FileUtils.rm_rf(output_dir) }

  def run_script
    `ruby #{script} --no-load --output-dir=#{output_dir} 2>&1`
  end

  it "loads without syntax errors" do
    output = `ruby -c #{script} 2>&1`
    expect($CHILD_STATUS.exitstatus).to eq(0)
    expect(output).to match(/Syntax OK/)
  end

  it "exits successfully with --no-load" do
    output = run_script
    expect($CHILD_STATUS.exitstatus).to eq(0), "Script failed:\n#{output}"
  end

  it "prints a message about the skipped perl command when --no-load is passed" do
    output = run_script
    expect(output).to match(/no.load.*disabled|not running|skipping/i)
    expect(output).to match(/xml2db\.pl/)
  end

  output_files_list = %w[people.xml representatives.xml senators.xml ministers.xml divisions.xml]
  output_files_list.each do |filename|
    it "produces #{filename} matching expected output" do
      run_script
      produced = File.join(output_dir, filename)
      expect(File).to exist(produced), "Expected #{produced} to be created"

      expected = File.join(expected_dir, filename)
      unless File.exist?(expected)
        FileUtils.cp(produced, expected)
        fail "Expected file missing — please review #{expected} and re-run"
      end

      expect(File.read(produced)).to eq(File.read(expected))
    end
  end
end

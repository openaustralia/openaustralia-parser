# frozen_string_literal: true

# DOES NOT APPEAR TO BE CALLED explicitly in Makefile/cron.
# Used to be run manually to find Wikipedia URLs for members.
# Calls mpinfoin.pl at the end — needs --no-load flag added to script.
# Uses Mechanize with Safari user-agent (Wikipedia blocks Ruby Mechanize).
# VCR cassette records Wikipedia HTTP responses.
# --limit=3 caps entries to keep cassette small.
#
# FIXME: script calls system("mpinfoin.pl links") unconditionally.
#        --no-load needs to be added to skip this. See parse-member-links.rb for pattern.

require_relative "../spec_helper"
require "fileutils"

RSpec.describe "wikipedia.rb", :integration, :vcr do
  let(:script)       { File.expand_path("../../wikipedia.rb", __dir__) }
  let(:expected_dir) { File.expand_path("../expected/wikipedia", __dir__) }
  let(:output_dir)   { File.expand_path("../../tmp/output/wikipedia", __dir__) }

  before { FileUtils.mkdir_p([expected_dir, output_dir]) }
  after  { FileUtils.rm_rf(output_dir) }

  def run_script
    `ruby #{script} --no-load --limit=3 --output-dir=#{output_dir} 2>&1`
  end

  it "loads without syntax errors" do
    output = `ruby -c #{script} 2>&1`
    expect($CHILD_STATUS.exitstatus).to eq(0)
    expect(output).to match(/Syntax OK/)
  end

  it "exits successfully with --no-load --limit=3" do
    output = run_script
    expect($CHILD_STATUS.exitstatus).to eq(0), "Script failed:\n#{output}"
  end

  it "prints a message about the skipped perl command when --no-load is passed" do
    output = run_script
    expect(output).to match(/no.load.*disabled|not running|skipping/i)
    expect(output).to match(/mpinfoin\.pl/)
  end

  it "produces wikipedia-commons.xml matching expected" do
    run_script
    produced = File.join(output_dir, "wikipedia-commons.xml")
    expect(File).to exist(produced), "Expected #{produced} to be created"

    expected = File.join(expected_dir, "wikipedia-commons.xml")
    unless File.exist?(expected)
      FileUtils.cp(produced, expected)
      fail "Expected file missing — please review #{expected} and re-run"
    end

    expect(File.read(produced)).to eq(File.read(expected))
  end

  it "produces wikipedia-lords.xml matching expected" do
    run_script
    produced = File.join(output_dir, "wikipedia-lords.xml")
    expect(File).to exist(produced), "Expected #{produced} to be created"

    expected = File.join(expected_dir, "wikipedia-lords.xml")
    unless File.exist?(expected)
      FileUtils.cp(produced, expected)
      fail "Expected file missing — please review #{expected} and re-run"
    end

    expect(File.read(produced)).to eq(File.read(expected))
  end
end

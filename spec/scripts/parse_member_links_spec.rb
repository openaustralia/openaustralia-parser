# frozen_string_literal: true

# Called from:
#   Makefile:46:        cd openaustralia-parser && bundle exec parse-member-links.rb
#   twfy/scripts/dailyupdate:9: (cd ../../openaustralia-parser; bundle exec parse-member-links.rb)
#
# --no-load flag needed: calls mpinfoin.pl at the end (perl script).
# --limit=N flag needed: makes many HTTP requests to morph.io, APH, ABC etc.
# VCR cassette records all HTTP except images.
#
# FIXME: The script also calls `system("mpinfoin.pl links")` which loads XML into the DB.
#        With --no-load this is skipped. Verify the XML output files are correct instead.

require_relative "../spec_helper"
require "fileutils"

RSpec.describe "parse-member-links.rb", :integration, :vcr do
  let(:script) { File.expand_path("../../parse-member-links.rb", __dir__) }
  let(:expected_dir) { File.expand_path("../expected/parse-member-links", __dir__) }
  let(:output_dir) { File.expand_path("../../tmp/output/parse-member-links", __dir__) }

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

  it "produces websites.xml" do
    run_script
    produced = File.join(output_dir, "websites.xml")
    expect(File).to exist(produced), "Expected #{produced} to be created"

    expected = File.join(expected_dir, "websites.xml")
    unless File.exist?(expected)
      FileUtils.cp(produced, expected)
      fail "Expected file missing — please review #{expected} and re-run"
    end

    expect(File.read(produced)).to eq(File.read(expected))
  end

  it "produces links-register-of-interests.xml" do
    run_script
    produced = File.join(output_dir, "links-register-of-interests.xml")
    expect(File).to exist(produced), "Expected #{produced} to be created"

    expected = File.join(expected_dir, "links-register-of-interests.xml")
    unless File.exist?(expected)
      FileUtils.cp(produced, expected)
      fail "Expected file missing — please review #{expected} and re-run"
    end

    expect(File.read(produced)).to eq(File.read(expected))
  end
end

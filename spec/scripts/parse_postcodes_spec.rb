# frozen_string_literal: true

# DOES NOT APPEAR TO BE CALLED explicitly in Makefile/cron, but postcodes.rb
# references the output CSV it produces. Likely run manually before postcodes.rb.
#
# Hits morph.io API to download postcode/electorate mapping CSV.
# VCR cassette records the morph.io response.

require_relative "../spec_helper"
require "fileutils"

RSpec.describe "parse-postcodes.rb", :integration, :vcr do
  let(:script)     { File.expand_path("../../parse-postcodes.rb", __dir__) }
  let(:output_csv) { File.expand_path("../../data/postcodes.csv", __dir__) }

  it "loads without syntax errors" do
    output = `ruby -c #{script} 2>&1`
    expect($CHILD_STATUS.exitstatus).to eq(0)
    expect(output).to match(/Syntax OK/)
  end

  it "exits successfully and produces postcodes.csv" do
    output = `ruby #{script} 2>&1`
    expect($CHILD_STATUS.exitstatus).to eq(0), "Script failed:\n#{output}"
    expect(File).to exist(output_csv)
  end

  it "postcodes.csv contains expected headers" do
    `ruby #{script} 2>&1`
    first_line = File.readlines(output_csv).first&.strip
    expect(first_line).to match(/postcode/i)
  end
end

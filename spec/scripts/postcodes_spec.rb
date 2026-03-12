# frozen_string_literal: true

# Called from:
#   README.md:80: bundle exec ./postcodes.rb --test
#
# --no-load flag already exists: skips DB INSERT when passed.
# Reads from data/postcodes.csv (produced by parse-postcodes.rb).
# With --no-load: validates CSV constituency names against members data only.

require_relative "../spec_helper"
require "fileutils"

RSpec.describe "postcodes.rb", :integration do
  let(:script) { File.expand_path("../../postcodes.rb", __dir__) }

  it "loads without syntax errors" do
    output = `ruby -c #{script} 2>&1`
    expect($CHILD_STATUS.exitstatus).to eq(0)
    expect(output).to match(/Syntax OK/)
  end

  it "exits successfully with --no-load" do
    output = `ruby #{script} --no-load 2>&1`
    expect($CHILD_STATUS.exitstatus).to eq(0), "Script failed:\n#{output}"
  end

  it "prints a message about the skipped DB load when --no-load is passed" do
    output = `ruby #{script} --no-load 2>&1`
    expect(output).to match(/no.load.*disabled|not running|skipping/i)
    expect(output).to match(/postcode_lookup|INSERT/i)
  end

  it "validates all constituencies in postcodes.csv are valid electoral divisions" do
    output = `ruby #{script} --no-load 2>&1`
    expect(output).not_to match(/Constituency .+ not found/i)
  end
end

# frozen_string_literal: true

# Reads from data/postcodes.csv (produced by parse-postcodes.rb).

require_relative "../spec_helper"
require_relative "../../postcodes"
require "fileutils"

RSpec.describe "postcodes.rb", :integration do
  let(:script) { File.expand_path("../../postcodes.rb", __dir__) }

  it "loads without syntax errors" do
    output = `ruby -c #{script} 2>&1`
    expect($CHILD_STATUS.exitstatus).to eq(0)
    expect(output).to match(/Syntax OK/)
  end

  it "runs its main code when started as `bundle exec ./postcodes.rb`" do
    output = Dir.chdir(File.dirname(script)) { `bundle exec ./postcodes.rb --no-load 2>&1` }
    expect($CHILD_STATUS.exitstatus).to eq(0), output
    expect(output).to match(/No-load option has disabled/)
  end

  it "exits successfully with --no-load" do
    expect { capture_stdout_and_stderr { Postcodes.new(["--no-load"]).run } }.not_to raise_error
  end

  it "prints a message about the skipped DB load when --no-load is passed" do
    output = capture_stdout_and_stderr { Postcodes.new(["--no-load"]).run }
    expect(output).to match(/no.load.*disabled|not running|skipping/i)
    expect(output).to match(/postcode_lookup|INSERT/i)
  end

  it "validates all constituencies in postcodes.csv are valid electoral divisions" do
    output = capture_stdout_and_stderr { Postcodes.new(["--no-load"]).run }
    expect(output).not_to match(/Constituency .+ not found/i)
  end
end

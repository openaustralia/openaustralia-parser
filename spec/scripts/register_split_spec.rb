# frozen_string_literal: true

# DOES NOT APPEAR TO BE CALLED!
# No references found in Makefile, cron scripts, Capfile or README.
# One-off tool for splitting Register of Members' Interests PDFs.
# Requires pdftk installed and specific PDF files under data/register_of_interests/.

require_relative "../spec_helper"

RSpec.describe "register-split.rb" do
  let(:script) { File.expand_path("../../register-split.rb", __dir__) }

  it "script file exists" do
    expect(File).to exist(script)
  end

  it "loads without syntax errors" do
    output = `ruby -c #{script} 2>&1`
    expect($CHILD_STATUS.exitstatus).to eq(0)
    expect(output).to match(/Syntax OK/)
  end

  it "requires pdftk to run" do
    source = File.read(script)
    expect(source).to include("pdftk")
  end
end

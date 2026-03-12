# frozen_string_literal: true

# DOES NOT APPEAR TO BE CALLED!
# No references found in any Makefile, cron script, Capfile or README.
# Likely a one-off migration tool paired with export-comments.rb.

require_relative "../spec_helper"

RSpec.describe "import-comments.rb" do
  let(:script) { File.expand_path("../../import-comments.rb", __dir__) }

  it "script file exists" do
    expect(File).to exist(script)
  end

  it "loads without syntax errors" do
    output = `ruby -c #{script} 2>&1`
    expect($CHILD_STATUS.exitstatus).to eq(0)
    expect(output).to match(/Syntax OK/)
  end

  it "expects exported-comments.csv as input" do
    source = File.read(script)
    expect(source).to include('exported-comments.csv')
  end
end

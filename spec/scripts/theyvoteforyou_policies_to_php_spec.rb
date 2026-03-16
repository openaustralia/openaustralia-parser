# frozen_string_literal: true

# DOES NOT APPEAR TO BE CALLED!
# Comment at top of script says output goes into a specific line of twfy PHP code.
# Marked as "No longer needed once we fix issue #545".
# One-off developer tool for generating PHP policy display code.
# Hits theyvoteforyou.org.au API — VCR cassette used.

require_relative "../spec_helper"
require_relative "../../theyvoteforyou_policies_to_php"

RSpec.describe "theyvoteforyou_policies_to_php.rb", :vcr do
  let(:script) { File.expand_path("../../theyvoteforyou_policies_to_php.rb", __dir__) }

  it "script file exists" do
    expect(File).to exist(script)
  end

  it "loads without syntax errors" do
    output = `ruby -c #{script} 2>&1`
    expect($CHILD_STATUS.exitstatus).to eq(0)
    expect(output).to match(/Syntax OK/)
  end

  it "outputs PHP display_dream_comparison calls" do
    output = capture_stdout_and_stderr { TvfyPoliciesToPhp.new([]).run }
    expect(output).to include("display_dream_comparison")
  end
end

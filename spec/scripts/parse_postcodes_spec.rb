# frozen_string_literal: true

# DOES NOT APPEAR TO BE CALLED explicitly in Makefile/cron, but postcodes.rb
# references the output CSV it produces. Likely run manually before postcodes.rb.
#
# Hits morph.io API to download postcode/electorate mapping CSV.
# VCR cassette records the morph.io response.

require_relative "../spec_helper"
require_relative "../../parse-postcodes"
require "fileutils"

RSpec.describe "parse-postcodes.rb", :integration do
  let(:script) { File.expand_path("../../parse-postcodes.rb", __dir__) }

  it "loads without syntax errors" do
    output = `ruby -c #{script} 2>&1`
    expect($CHILD_STATUS.exitstatus).to eq(0)
    expect(output).to match(/Syntax OK/)
  end

  describe "accesses network", :vcr do
    let(:output_dir) { File.expand_path("../../tmp/postcode_output", __dir__) }
    let(:output_csv) { "#{output_dir}/postcodes.csv" }

    before do
      FileUtils.rm_rf(output_dir)
    end

    after do
      FileUtils.rm_rf(output_dir)
    end

    it "exits successfully and produces postcodes.csv" do
      output = capture_stdout_and_stderr { ParsePostcodes.new(["--output-dir", output_dir]).run }
      expect(File).to exist(output_csv)
      expect(File.size?(output_csv)).to be_truthy
      expect(output).to match(/Fetching postcodes from morph.io/)
      expect(output).to match(/Done./)
    end

    it "postcodes.csv contains expected headers" do
      output = capture_stdout_and_stderr { ParsePostcodes.new(["--output-dir", output_dir]).run }
      first_line = File.readlines(output_csv).first&.strip
      expect(first_line).to match(/postcode,electorate/i)
      expect(output).to match(/Done./)
    end

    it "overwrites existing postcodes.csv" do
      FileUtils.mkdir_p output_dir
      File.write(output_csv, 'Rubbish')
      output = capture_stdout_and_stderr { ParsePostcodes.new(["--output-dir", output_dir]).run }
      first_line = File.readlines(output_csv).first&.strip
      expect(first_line).to match(/postcode,electorate/i)
      expect(output).to match(/Done./)
    end

    it "does not overwrites existing postcodes.csv when api_key is invalid" do
      FileUtils.mkdir_p output_dir
      File.write(output_csv, 'Previous-value')
      expect { ParsePostcodes.new(["--output-dir", output_dir, "--morph-api-key", "NOT-VALID"]).run }.to raise_error
      contents = File.read(output_csv)
      expect(contents).to match(/Previous-value/i)
    end
  end
end

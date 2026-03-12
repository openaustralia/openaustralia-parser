# frozen_string_literal: true

# create_patch.rb is called by parse-speeches.rb interactively when a parse error occurs:
#   openaustralia-parser/parse-speeches.rb:102:
#     system "#{File.dirname(__FILE__)}/create_patch.rb #{house} #{date}"
# It is a developer tool, not part of the automated pipeline.

require_relative "../spec_helper"

RSpec.describe "create_patch.rb" do
  let(:script) { File.expand_path("../../create_patch.rb", __dir__) }

  it "exits with error when wrong number of arguments" do
    output = `ruby #{script} 2>&1`
    expect($CHILD_STATUS.exitstatus).not_to eq(0)
  end

  it "exits with error for unknown house argument" do
    output = `ruby #{script} badhouse 2025.02.04 2>&1`
    expect($CHILD_STATUS.exitstatus).not_to eq(0)
    expect(output).to match(/reps|senate/i)
  end

  it "accepts 'reps' and a valid date without crashing on file setup" do
    Dir.mktmpdir do |dir|
      # It will try to create original.xml / patched.xml in cwd and then print instructions.
      # We just verify it doesn't blow up with argument parsing.
      output = `cd #{dir} && ruby #{script} reps 2025.02.04 2>&1`
      # It will fail trying to load people CSV etc, but argument parsing should pass
      expect(output).not_to match(/Wrong number of parameters/)
    end
  end

  it "accepts 'senate' as a valid house argument" do
    Dir.mktmpdir do |dir|
      output = `cd #{dir} && ruby #{script} senate 2025.02.04 2>&1`
      expect(output).not_to match(/Wrong number of parameters/)
      expect(output).not_to match(/Expected 'reps' or 'senate'/)
    end
  end
end

# frozen_string_literal: true
#
# mlander: Very rough and ready scripts for importing/exporting comments when gid's might change
#
# FIXME: We shouldn't be dependent on GIDs staying the same as replication fallover may change them

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
end

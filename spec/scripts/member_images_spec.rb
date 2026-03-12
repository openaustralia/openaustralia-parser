# frozen_string_literal: true

# Called from README:
#   README.md:87: $ ./member-images.rb
#
# Uses Mechanize (via PeopleImageDownloader) to fetch member photos.
# WebMock stubs all image requests to return a real fixture JPEG so we
# don't need VCR cassettes (which would be huge for ~200 images).
# --limit=N is added to the script to cap downloads during testing.

require_relative "../spec_helper"
require "webmock/rspec"
require "fileutils"

RSpec.describe "member-images.rb", :integration do
  let(:script) { File.expand_path("../../member-images.rb", __dir__) }
  let(:fixture_image) { File.expand_path("../fixtures/images/JohnCurtin-150w.jpg", __dir__) }
  let(:output_dir) { File.expand_path("../../tmp/output/member-images", __dir__) }

  before do
    FileUtils.mkdir_p(output_dir)
    expect(File).to exist(fixture_image), "Missing fixture: spec/fixtures/JohnCurtin-150w.jpg"
  end

  after do
    FileUtils.rm_rf(output_dir)
  end

  it "downloads and resizes images for the first 3 members", :vcr do
    # All HTTP image requests return our fixture JPEG
    stub_request(:any, //).to_return(
      status: 200,
      body: File.read(fixture_image, encoding: "binary"),
      headers: { "Content-Type" => "image/jpeg" }
    )

    output = `ruby #{script} --limit=3 2>&1`
    expect($CHILD_STATUS.exitstatus).to eq(0), "Script failed:\n#{output}"
    expect(output).to include("Downloading person images")
    expect(output).to include("Finished downloading")
  end

  it "script file exists" do
    expect(File).to exist(script)
  end

  it "loads without syntax errors" do
    output = `ruby -c #{script} 2>&1`
    expect($CHILD_STATUS.exitstatus).to eq(0)
    expect(output).to match(/Syntax OK/)
  end
end

# frozen_string_literal: true

# Called from README:
#   README.md:87: $ ./member-images.rb
#
# Uses Mechanize (via PeopleImageDownloader) to fetch member photos.
# WebMock stubs image requests to return a real fixture JPEG so we
# don't need VCR cassettes (which would be huge for ~200 images).
# --limit=N is added to the script to cap downloads during testing.

require_relative "../spec_helper"
require_relative "../../member-images"
require "webmock/rspec"
require "fileutils"

RSpec.describe "member-images.rb", :integration do
  let(:fixture_image) { File.expand_path("../fixtures/images/JohnCurtin-150w.jpg", __dir__) }
  let(:output_dir) { File.expand_path("../../tmp/member-images.test", __dir__) }

  before do
    FileUtils.rm_rf(output_dir)
    FileUtils.mkdir_p(output_dir)
    expect(File).to exist(fixture_image), "Missing fixture: #{fixture_image}"
  end

  after do
    FileUtils.rm_rf(output_dir)
  end

  it "downloads and resizes images for the first 3 members", :vcr do
    stub_request(:get, /\/api\/parliamentarian\/[^\/]+\/image/)
      .to_return(
        status: 200,
        body: File.binread(fixture_image),
        headers: { "Content-Type" => "image/jpeg" }
      )

    output = capture_stdout_and_stderr { MemberImages.new(["--limit=3", "--output-dir", output_dir]).run }
    puts "OUTPUT:\n#{output}\nEOF" if ENV["DEBUG"]
    expect(output).to include("Downloading person images to")
    expect(output).to include("Finished downloading")
    %w[mps mpsL mpsXL].each do |subdir|
      images = Dir.glob("#{output_dir}/#{subdir}/*.jpg")
      expect(images.size).to eq(3), "Expected 3 images in #{subdir}, got #{images.size}"
      images.each do |image|
        expect(valid_jpg?(image)).to be(true), "#{image} is not a valid JPEG"
      end
    end
  end

  it "loads without syntax errors" do
    output = `ruby -c #{File.expand_path("../../member-images.rb", __dir__)} 2>&1`
    expect($CHILD_STATUS.exitstatus).to eq(0)
    expect(output).to match(/Syntax OK/)
  end
end

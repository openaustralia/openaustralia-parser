# frozen_string_literal: true

# Called from:
#   twfy/scripts/morningupdate:73:
#     (cd ../../openaustralia-parser; bundle exec sitemap.rb)
#   README.md:146: Known issue with PINGMYMAP_API_URL constant
#
# Reads from DB (hansard, member, comments tables).
# Writes sitemap.xml and sitemaps/sitemapN.xml.gz files.
# No --no-load needed (no perl/php calls).
# No VCR needed (no external HTTP — all DB reads).

require_relative "../spec_helper"
require_relative "../../sitemap"
require "fileutils"

RSpec.describe "sitemap.rb", :integration do
  let(:script) { File.expand_path("../../sitemap.rb", __dir__) }
  let(:output_dir) { File.expand_path("../../tmp/output/sitemap", __dir__) }

  before { FileUtils.mkdir_p(output_dir) }
  after { FileUtils.rm_rf(output_dir) }

  it "loads without syntax errors" do
    output = `ruby -c #{script} 2>&1`
    expect($CHILD_STATUS.exitstatus).to eq(0)
    expect(output).to match(/Syntax OK/)
  end

  describe "uses db", :db do
    it "exits successfully and produces sitemap.xml" do
      capture_stdout_and_stderr { SitemapGenerator.new(["--output-dir=#{output_dir}"]).run }
      sitemap = File.join(output_dir, "sitemap.xml")
      expect(File).to exist(sitemap)
    end

    it "sitemap.xml is valid XML with sitemapindex root" do
      capture_stdout_and_stderr { SitemapGenerator.new(["--output-dir=#{output_dir}"]).run }
      sitemap = File.join(output_dir, "sitemap.xml")
      content = File.read(sitemap)
      expect(content).to include("<sitemapindex")
      expect(content).to include("sitemaps.org/schemas/sitemap")
    end

    it "produces at least one compressed sitemap file" do
      capture_stdout_and_stderr { SitemapGenerator.new(["--output-dir=#{output_dir}"]).run }
      sitemaps_dir = File.join(output_dir, "sitemaps")
      gz_files = Dir.glob("#{sitemaps_dir}/*.xml.gz")
      expect(gz_files).not_to be_empty
    end
  end
end

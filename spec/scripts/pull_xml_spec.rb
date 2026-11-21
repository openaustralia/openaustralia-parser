# frozen_string_literal: true

# A development tool that copies production's origxml cache; nothing schedules it.

require_relative "../spec_helper"

require "stringio"
require "tmpdir"
require "webmock/rspec"

require_relative "../../pull-xml"

RSpec.describe PullXml do
  let(:output_dir) { Dir.mktmpdir }
  let(:stdout) { StringIO.new }
  let(:arguments) { [] }
  let(:script) do
    described_class.new(["--from=2026-02-04", "--to=2026-02-05", "--house=senate", "--output-dir=#{output_dir}", *arguments], stdout: stdout)
  end

  def directory_url
    "https://data.openaustralia.org.au/origxml/senate_debates"
  end

  def modified
    "Wed, 04 Feb 2026 22:05:11 GMT"
  end

  def local_file
    File.join(output_dir, "origxml", "senate_debates", "2026-02-04.xml")
  end

  def hansard(date, text = "new")
    "<hansard><session.header><date>#{date}</date></session.header><note>#{text}</note></hansard>"
  end

  before do
    listing = %w[2026-02-03 2026-02-04 2026-02-05 2026-02-06].map { |date| %(<a href="#{date}.xml">#{date}.xml</a>) }.join
    stub_request(:get, "#{directory_url}/").to_return(body: listing)
    %w[2026-02-04 2026-02-05].each do |date|
      stub_request(:get, "#{directory_url}/#{date}.xml").to_return(body: hansard(date), headers: { "Last-Modified" => modified })
    end
    allow(script).to receive(:sleep)
  end

  after { FileUtils.remove_entry(output_dir) }

  def write_local(text, modified_at)
    FileUtils.mkdir_p(File.dirname(local_file))
    File.write(local_file, text)
    File.utime(modified_at, modified_at, local_file)
  end

  it "downloads the days in the range that are missing locally" do
    script.run
    expect(File.read(local_file)).to include("<note>new</note>")
  end

  it "leaves out the days outside the range" do
    script.run
    expect(WebMock).not_to have_requested(:get, "#{directory_url}/2026-02-06.xml")
  end

  it "gives the file the time the server last changed it" do
    script.run
    expect(File.mtime(local_file)).to eq(Time.httpdate(modified))
  end

  it "asks only for what changed since the local file" do
    write_local(hansard("2026-02-04", "local"), Time.httpdate(modified))
    stub_request(:get, "#{directory_url}/2026-02-04.xml").with(headers: { "If-Modified-Since" => modified }).to_return(status: 304)
    script.run
    expect(File.read(local_file)).to include("<note>local</note>")
  end

  it "replaces a local file that is older than the server's" do
    write_local(hansard("2026-02-04", "local"), Time.httpdate(modified) - 86_400)
    script.run
    expect(File.read(local_file)).to include("<note>new</note>")
  end

  context "with --force" do
    let(:arguments) { ["--force"] }

    it "downloads even when the local file is as new" do
      write_local(hansard("2026-02-04", "local"), Time.httpdate(modified))
      script.run
      expect(File.read(local_file)).to include("<note>new</note>")
    end
  end

  context "with --dry-run" do
    let(:arguments) { ["--dry-run"] }

    it "downloads nothing" do
      script.run
      expect(WebMock).not_to have_requested(:get, "#{directory_url}/2026-02-04.xml")
    end

    it "says which days are not present locally" do
      script.run
      expect(stdout.string).to include("2026-02-04 not present locally")
    end
  end

  context "with --source=scrapedxml" do
    let(:arguments) { ["--source=scrapedxml"] }
    let(:scraped_file) { File.join(output_dir, "scrapedxml", "senate_debates", "2026-02-04.xml") }

    def debates(date)
      %(<debates><major-heading id="uk.org.publicwhip/lords/#{date}.3.1">HEADING</major-heading></debates>)
    end

    before do
      listing = %(<a href="2026-02-04.xml">2026-02-04.xml</a>)
      stub_request(:get, "https://data.openaustralia.org.au/scrapedxml/senate_debates/").to_return(body: listing)
      stub_request(:get, "https://data.openaustralia.org.au/scrapedxml/senate_debates/2026-02-04.xml")
        .to_return(body: debates("2026-02-04"), headers: { "Last-Modified" => modified })
    end

    it "saves the day under scrapedxml" do
      script.run
      expect(File.read(scraped_file)).to include("HEADING")
    end

    it "leaves origxml alone" do
      script.run
      expect(WebMock).not_to have_requested(:get, "#{directory_url}/2026-02-04.xml")
    end

    it "does not save a file that is origxml" do
      stub_request(:get, "https://data.openaustralia.org.au/scrapedxml/senate_debates/2026-02-04.xml")
        .to_return(body: hansard("2026-02-04"), headers: { "Last-Modified" => modified })
      expect { script.run }.to raise_error(SystemExit)
      expect(File).not_to exist(scraped_file)
    end
  end

  context "when a day has an empty file because there was no sitting" do
    before do
      stub_request(:get, "#{directory_url}/2026-02-04.xml").to_return(body: "", headers: { "Last-Modified" => modified })
    end

    it "saves the empty file, as the parser's cache does" do
      script.run
      expect(File.size(local_file)).to eq(0)
    end

    it "does not count it as a failure" do
      expect { script.run }.not_to raise_error
    end
  end

  context "when a file is for another day" do
    before do
      stub_request(:get, "#{directory_url}/2026-02-04.xml").to_return(body: hansard("2026-02-09"), headers: { "Last-Modified" => modified })
    end

    it "does not save it and exits with an error" do
      expect { script.run }.to raise_error(SystemExit)
      expect(File).not_to exist(local_file)
    end
  end

  context "when the server asks us to slow down" do
    before { stub_request(:get, "#{directory_url}/2026-02-04.xml").to_return(status: 429) }

    it "stops without asking for the next day" do
      script.run
      expect(WebMock).not_to have_requested(:get, "#{directory_url}/2026-02-05.xml")
    end
  end

  context "without --from" do
    let(:script) { described_class.new(["--output-dir=#{output_dir}"], stdout: stdout) }

    it "refuses to copy the whole archive" do
      expect { script.run }.to raise_error(SystemExit)
    end
  end
end

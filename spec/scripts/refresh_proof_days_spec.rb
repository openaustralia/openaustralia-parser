# frozen_string_literal: true

# Run by a person when proof days need refreshing; nothing schedules it. See openaustralia/openaustralia#1058.

require_relative "../spec_helper"

require "tmpdir"

require_relative "../../refresh-proof-days"

RSpec.describe RefreshProofDays do
  let(:output_dir) { Dir.mktmpdir }
  let(:parser) do
    instance_double(HansardParser, proof_days: days, days_without_proof_flag: days, cached_proof: true,
                                   parse_date_house_only_in_proof: nil, parse_date_house: nil, house_directory_name: "senate_debates")
  end
  let(:days) { [[Date.new(2026, 2, 5), House.senate], [Date.new(2026, 2, 4), House.senate]] }
  let(:script) { described_class.new(["--output-dir=#{output_dir}", *arguments]) }
  let(:arguments) { [] }

  before do
    allow(PeopleCSVReader).to receive(:read_members).and_return(People.new)
    allow(HansardParser).to receive(:new).and_return(parser)
    allow(script).to receive(:system)
    allow(script).to receive(:puts)
  end

  after { FileUtils.remove_entry(output_dir) }

  it "asks for 100 days by default" do
    script.run
    expect(parser).to have_received(:proof_days).with(limit: 100)
  end

  context "with --limit" do
    let(:arguments) { ["--limit=5"] }

    it "passes the limit on" do
      script.run
      expect(parser).to have_received(:proof_days).with(limit: 5)
    end
  end

  it "refreshes each day, then loads each date once" do
    script.run
    expect(parser).to have_received(:parse_date_house_only_in_proof).twice
    expect(script).to have_received(:system).with(a_string_including("--from=2026-02-04 --to=2026-02-04")).once
    expect(script).to have_received(:system).with(a_string_including("--from=2026-02-05 --to=2026-02-05")).once
  end

  context "with --unknown" do
    let(:arguments) { ["--unknown", "--limit=3"] }

    it "works on the days with no proof flag instead of the proof days" do
      script.run
      expect(parser).to have_received(:days_without_proof_flag).with(limit: 3)
      expect(parser).not_to have_received(:proof_days)
    end

    it "refreshes a day whose cached copy is proof from aph" do
      script.run
      expect(parser).to have_received(:parse_date_house_only_in_proof).twice
      expect(parser).not_to have_received(:parse_date_house)
    end

    it "parses a day whose cached copy is final from the cache, without asking aph" do
      allow(parser).to receive(:cached_proof).and_return(false)
      script.run
      expect(parser).to have_received(:parse_date_house).twice
      expect(parser).not_to have_received(:parse_date_house_only_in_proof)
    end
  end

  context "with --no-load" do
    let(:arguments) { ["--no-load"] }

    it "does not load the database" do
      script.run
      expect(script).not_to have_received(:system)
    end
  end

  context "when one day fails" do
    before do
      allow(parser).to receive(:parse_date_house_only_in_proof).with(Date.new(2026, 2, 5), anything, anything).and_raise("boom")
    end

    it "carries on with the other days, loads only those that worked, and exits with an error" do
      expect { script.run }.to raise_error(SystemExit) { |error| expect(error.status).to eq 1 }
      expect(parser).to have_received(:parse_date_house_only_in_proof).twice
      expect(script).to have_received(:system).with(a_string_including("--from=2026-02-04")).once
      expect(script).not_to have_received(:system).with(a_string_including("--from=2026-02-05"))
    end
  end
end

# frozen_string_literal: true

require_relative "../spec_helper"
require "hansard_speech"
require "hansard_parser"
require "people"
require "tmpdir"

# Two classes both live in hansard_parser.rb (see HansardSpeech below), so
# this file already predates the one-describe-per-file convention.
# rubocop:disable RSpec/MultipleDescribes
RSpec.describe HansardParser do
  describe "#unmatched_name_details" do
    let(:people) { People.new }
    let(:parser) { HansardParser.new(people) }

    it "says 'not found' and names the house being searched when no candidate matches the name at all" do
      details = parser.unmatched_name_details(Name.new(first: "Nobody", last: "Nowhere"), House.senate)
      expect(details).to eq "not found (looking in senate)"
    end

    it "lists each candidate's IDs and house/period when the name matches but no period fits" do
      people << Person.new(name: Name.new(first: "Jane", last: "Doe"), count: 42, aph_id: "ABC123")
      people.last.add_period(from_date: Date.new(2010, 1, 1), to_date: Date.new(2013, 1, 1),
                             house: House.senate, division: "Testville", party: "ALP", count: 7)

      details = parser.unmatched_name_details(Name.new(first: "Jane", last: "Doe"), House.senate)

      expect(details).to start_with("not sitting in senate - ")
      expect(details).to include("uk.org.publicwhip/person/10042")
      expect(details).to include("aph_id=\"ABC123\"")
      expect(details).to include("Jane Doe")
      expect(details).to include("senate")
      expect(details).to include("uk.org.publicwhip/lord/100007")
      expect(details).to include("2010-01-01 to 2013-01-01")
    end

    it "flags a candidate whose period was in the other house" do
      people << Person.new(name: Name.new(first: "Jane", last: "Doe"), count: 42, aph_id: "ABC123")
      people.last.add_period(from_date: Date.new(2010, 1, 1), to_date: Date.new(2013, 1, 1),
                             house: House.representatives, division: "Testville", party: "ALP", count: 7)

      details = parser.unmatched_name_details(Name.new(first: "Jane", last: "Doe"), House.senate)

      expect(details).to include("representatives, NOT senate:")
    end
  end

  describe "#parse_date_house with an odd number of names in a division's pairs" do
    let(:date) { Date.new(2026, 10, 12) }
    let(:output_dir) { Dir.mktmpdir }
    let(:people) do
      People.new.tap do |people|
        { "Jane" => "Doe", "John" => "Roe", "Mary" => "Poe" }.each_with_index do |(first, last), i|
          people << Person.new(name: Name.new(first: first, last: last), count: i + 1, aph_id: "ID#{i}")
          people.last.add_period(from_date: Date.new(2020, 1, 1), to_date: Date.new(2030, 1, 1),
                                 house: House.senate, division: "Testville", party: "ALP", count: i + 1)
        end
      end
    end
    let(:parser) { HansardParser.new(people, output_dir: output_dir) }

    def xml_filename
      File.join(output_dir, "senate-2026-10-12.xml")
    end

    def divisions
      Nokogiri::XML(File.read(xml_filename)).xpath("//division")
    end

    def division(names)
      sitting = double(permanent_url: "http://foo/day", add_speaker_to_tied_votes?: false)
      HansardDivision.new(Nokogiri::XML(
                            "<division>
                               <division.header><time.stamp>13:28:00</time.stamp></division.header>
                               <division.data>
                                 <pairs><names>#{names.map { |n| "<name>#{n}</name>" }.join}</names></pairs>
                               </division.data>
                             </division>"
                          ), "Bills", "In committee", [], sitting)
    end

    before do
      day = double(pages: [division(["Doe, Jane", "Roe, John", "Poe, Mary"]), division(["Doe, Jane", "Roe, John"])],
                   permanent_url: "http://foo/day", in_proof?: false, proof: false)
      allow(parser).to receive(:hansard_day_on_date).and_return(day)
      allow(parser).to receive(:puts)
      allow(parser.logger).to receive(:warn)
      parser.parse_date_house(date, xml_filename, House.senate)
    end

    after { FileUtils.remove_entry(output_dir) }

    it "logs a warning that lists the names" do
      expect(parser.logger).to have_received(:warn).with(
        a_string_including("Not an even number of people in the pairs voting (3 names)", "  3. Poe, Mary")
      )
    end

    it "writes the division and the one after it" do
      expect(divisions.size).to eq 2
    end

    it "writes every name in the odd list as unpaired, and writes no pairs for it" do
      expect(divisions.first.xpath("unpaired/member").map(&:text)).to eq ["Jane Doe", "John Roe", "Mary Poe"]
      expect(divisions.first.xpath("pairs")).to be_empty
    end

    it "still pairs the names in a list with an even number of names" do
      expect(divisions.last.xpath("pairs/pair").size).to eq 1
      expect(divisions.last.xpath("unpaired")).to be_empty
    end
  end

  describe "#proof_days" do
    let(:output_dir) { Dir.mktmpdir }
    let(:parser) { HansardParser.new(People.new, output_dir: output_dir) }

    def cache(house, date, text)
      filename = parser.origxml_filename(Date.iso8601(date), house)
      FileUtils.mkdir_p(File.dirname(filename))
      File.write(filename, text)
    end

    def day_xml(proof)
      "<hansard><session.header><proof>#{proof}</proof></session.header></hansard>"
    end

    after { FileUtils.remove_entry(output_dir) }

    it "lists the days at proof stage, most recent first, the Representatives before the Senate" do
      cache(House.senate, "2026-02-04", day_xml(1))
      cache(House.representatives, "2026-02-04", day_xml(1))
      cache(House.representatives, "2026-02-03", day_xml(1))
      cache(House.senate, "2026-03-10", day_xml(1))

      expect(parser.proof_days(limit: 10)).to eq [
        [Date.new(2026, 3, 10), House.senate],
        [Date.new(2026, 2, 4), House.representatives],
        [Date.new(2026, 2, 4), House.senate],
        [Date.new(2026, 2, 3), House.representatives]
      ]
    end

    it "leaves out final days, days with no data, and days with no proof tag" do
      cache(House.senate, "2026-02-04", day_xml(0))
      cache(House.senate, "2026-02-05", "")
      cache(House.senate, "2026-02-06", "<hansard></hansard>")
      cache(House.senate, "2026-02-03", day_xml(1))

      expect(parser.proof_days(limit: 10)).to eq [[Date.new(2026, 2, 3), House.senate]]
    end

    it "stops at the limit, keeping the most recent days" do
      cache(House.senate, "2026-02-03", day_xml(1))
      cache(House.senate, "2026-02-04", day_xml(1))
      cache(House.senate, "2026-02-05", day_xml(1))

      expect(parser.proof_days(limit: 2)).to eq [[Date.new(2026, 2, 5), House.senate], [Date.new(2026, 2, 4), House.senate]]
    end

    it "returns nothing when there is no cache" do
      expect(parser.proof_days(limit: 10)).to eq []
    end
  end

  describe "days with no proof flag" do
    let(:output_dir) { Dir.mktmpdir }
    let(:parser) { HansardParser.new(People.new, output_dir: output_dir) }

    def cache(house, date, proof:, flagged:)
      origxml = parser.origxml_filename(Date.iso8601(date), house)
      FileUtils.mkdir_p(File.dirname(origxml))
      File.write(origxml, "<hansard><session.header><proof>#{proof}</proof></session.header></hansard>")
      scrapedxml = "#{output_dir}/scrapedxml/#{parser.house_directory_name(house)}/#{date}.xml"
      FileUtils.mkdir_p(File.dirname(scrapedxml))
      File.write(scrapedxml, %(<?xml version="1.0" encoding="UTF-8"?>\n<debates#{' proof="1"' if flagged}>\n</debates>\n))
    end

    after { FileUtils.remove_entry(output_dir) }

    describe "#days_without_proof_flag" do
      it "lists final and proof days whose scrapedxml has no proof attribute, most recent first" do
        cache(House.senate, "2026-02-03", proof: 1, flagged: false)
        cache(House.representatives, "2026-02-04", proof: 0, flagged: false)
        cache(House.senate, "2026-02-04", proof: 0, flagged: false)

        expect(parser.days_without_proof_flag(limit: 10)).to eq [
          [Date.new(2026, 2, 4), House.representatives],
          [Date.new(2026, 2, 4), House.senate],
          [Date.new(2026, 2, 3), House.senate]
        ]
      end

      it "leaves out days that already have the attribute" do
        cache(House.senate, "2026-02-03", proof: 1, flagged: true)
        cache(House.senate, "2026-02-04", proof: 0, flagged: true)

        expect(parser.days_without_proof_flag(limit: 10)).to eq []
      end

      it "leaves out days with no scrapedxml, no data, or a blank proof value" do
        cache(House.senate, "2026-02-03", proof: "", flagged: false)
        FileUtils.mkdir_p(File.dirname(parser.origxml_filename(Date.new(2026, 2, 4), House.senate)))
        File.write(parser.origxml_filename(Date.new(2026, 2, 4), House.senate), "<hansard><proof>0</proof></hansard>")
        File.write(parser.origxml_filename(Date.new(2026, 2, 5), House.senate), "")

        expect(parser.days_without_proof_flag(limit: 10)).to eq []
      end

      it "stops at the limit, keeping the most recent days" do
        cache(House.senate, "2026-02-03", proof: 0, flagged: false)
        cache(House.senate, "2026-02-04", proof: 0, flagged: false)

        expect(parser.days_without_proof_flag(limit: 1)).to eq [[Date.new(2026, 2, 4), House.senate]]
      end
    end

    describe "#cached_proof" do
      it "is true, false or nil as the cached origxml says" do
        cache(House.senate, "2026-02-03", proof: 1, flagged: false)
        cache(House.senate, "2026-02-04", proof: 0, flagged: false)
        cache(House.senate, "2026-02-05", proof: "", flagged: false)

        expect([3, 4, 5, 6].map { |day| parser.cached_proof(Date.new(2026, 2, day), House.senate) }).to eq [true, false, nil, nil]
      end
    end
  end

  describe "refreshing the cached origxml of a proof day" do
    let(:date) { Date.new(2026, 2, 4) }
    let(:output_dir) { Dir.mktmpdir }
    let(:parser) { HansardParser.new(People.new, output_dir: output_dir) }
    let(:filename) { parser.origxml_filename(date, House.senate) }
    let(:cached) { hansard_xml(proof: 1) }

    def hansard_xml(proof:, day: date)
      "<hansard><session.header><date>#{day}</date><proof>#{proof}</proof></session.header></hansard>"
    end

    before do
      FileUtils.mkdir_p(File.dirname(filename))
      File.write(filename, cached)
      allow(parser.logger).to receive(:warn)
      allow(parser.logger).to receive(:error)
    end

    after { FileUtils.remove_entry(output_dir) }

    it "replaces the cached copy with a valid fresh copy that differs" do
      fresh = hansard_xml(proof: 0)
      allow(parser).to receive(:hansard_xml_source_data_on_date).and_return(fresh)

      expect(parser.refresh_origxml(date, House.senate)).to eq :replaced
      expect(File.read(filename)).to eq fresh
      expect(File.exist?("#{filename}.new")).to be false
    end

    it "leaves the cached copy alone when the fresh copy is the same" do
      allow(parser).to receive(:hansard_xml_source_data_on_date).and_return(cached)

      expect(parser.refresh_origxml(date, House.senate)).to eq :unchanged
      expect(File.read(filename)).to eq cached
    end

    {
      "aph has no copy" => nil,
      "the fresh copy is empty" => "",
      "the fresh copy is not a hansard document" => "<html><body>Unavailable</body></html>"
    }.each do |reason, fresh|
      it "keeps the cached copy when #{reason}" do
        allow(parser).to receive(:hansard_xml_source_data_on_date).and_return(fresh)

        expect(parser.refresh_origxml(date, House.senate)).to eq :kept
        expect(File.read(filename)).to eq cached
        expect(parser.logger).to have_received(:warn).with(a_string_including("keeping the cached origxml"))
      end
    end

    it "keeps the cached copy when the fresh copy is for another day" do
      allow(parser).to receive(:hansard_xml_source_data_on_date).and_return(hansard_xml(proof: 0, day: date - 1))

      expect(parser.refresh_origxml(date, House.senate)).to eq :kept
      expect(File.read(filename)).to eq cached
      expect(parser.logger).to have_received(:warn).with(a_string_including("it is for 2026-02-03, not 2026-02-04"))
    end

    it "keeps the cached copy and logs an error when the download or its patch fails" do
      allow(parser).to receive(:hansard_xml_source_data_on_date).and_raise("2026-02-04 senate: Patch failed")

      expect(parser.refresh_origxml(date, House.senate)).to eq :kept
      expect(File.read(filename)).to eq cached
      expect(parser.logger).to have_received(:error).with(a_string_including("Patch failed", "keeping the cached origxml"))
    end

    describe "#parse_date_house_only_in_proof" do
      def xml_filename
        File.join(output_dir, "out.xml")
      end

      before do
        allow(parser).to receive(:refresh_origxml)
        allow(parser).to receive(:parse_date_house)
      end

      it "refreshes a cached proof day, then parses it" do
        allow(parser).to receive(:hansard_day_on_date).and_return(instance_double(HansardDay, in_proof?: true))

        parser.parse_date_house_only_in_proof(date, xml_filename, House.senate)

        expect(parser).to have_received(:refresh_origxml).with(date, House.senate).ordered
        expect(parser).to have_received(:parse_date_house).with(date, xml_filename, House.senate).ordered
      end

      it "skips a day that is not at proof stage" do
        allow(parser).to receive(:hansard_day_on_date).and_return(instance_double(HansardDay, in_proof?: false))

        parser.parse_date_house_only_in_proof(date, xml_filename, House.senate)

        expect(parser).not_to have_received(:refresh_origxml)
        expect(parser).not_to have_received(:parse_date_house)
      end

      it "does not download a day again when this run has just fetched it" do
        FileUtils.rm_f(filename)
        allow(parser).to receive(:hansard_day_on_date).and_return(instance_double(HansardDay, in_proof?: true))

        parser.parse_date_house_only_in_proof(date, xml_filename, House.senate)

        expect(parser).not_to have_received(:refresh_origxml)
        expect(parser).to have_received(:parse_date_house)
      end
    end
  end
end

RSpec.describe HansardSpeech do
  describe ".generic_speaker?" do
    %w[
      Honourable\ member
      Honourable\ members
      Government\ member
      Government\ members
      Opposition\ member
      Opposition\ members
      a\ government\ member
    ].each do |name|
      it "recognises '#{name}' as a generic speaker" do
        expect(HansardSpeech.generic_speaker?(name)).to be_truthy
      end
    end

    it "does not treat a real name as a generic speaker" do
      expect(HansardSpeech.generic_speaker?("John Smith")).to be_falsy
    end
  end
end
# rubocop:enable RSpec/MultipleDescribes

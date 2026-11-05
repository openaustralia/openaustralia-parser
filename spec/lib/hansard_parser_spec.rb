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

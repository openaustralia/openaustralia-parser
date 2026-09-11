# frozen_string_literal: true

require_relative "../spec_helper"
require "hansard_speech"
require "hansard_parser"
require "people"

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

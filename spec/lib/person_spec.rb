# frozen_string_literal: true

require_relative "../spec_helper"
require "date"

require "person"
require "name"

RSpec.describe Person do
  let(:john_smith) { Name.new(first: "John", last: "Smith") }
  let(:jack_smith) { Name.new(first: "Jack", last: "Smith") }

  def make_person(name:, count:, division: "division1", party: "party1")
    p = Person.new(name: name, count: count)
    p.add_period(house: House.representatives, division: division, party: party,
                 from_date: Date.new(2000, 1, 1), to_date: Date.new(2001, 1, 1),
                 from_why: "general_election", to_why: "defeated", count: count)
    p
  end

  it "considers two people with the same attributes equal" do
    expect(make_person(name: john_smith, count: 1)).to eq make_person(name: john_smith, count: 1)
  end

  it "considers two people with different names not equal" do
    henry_jones = Name.new(first: "Henry", last: "Jones")
    expect(make_person(name: john_smith, count: 1)).not_to eq make_person(name: henry_jones, count: 2, division: "division2", party: "party2")
  end

  it "tracks multiple names" do
    person = Person.new(count: 1, name: john_smith, alternate_names: [jack_smith])
    expect(person.name).to eq john_smith
    expect(person.alternate_names).to eq [jack_smith]
    expect(person.all_names).to eq [john_smith, jack_smith]
  end

  it "matches by primary and alternate names" do
    henry_smith = Name.new(first: "Henry", last: "Smith")
    person = Person.new(count: 1, name: john_smith, alternate_names: [jack_smith])
    expect(person.name_matches?(john_smith)).to be true
    expect(person.name_matches?(jack_smith)).to be true
    expect(person.name_matches?(henry_smith)).to be false
  end
end

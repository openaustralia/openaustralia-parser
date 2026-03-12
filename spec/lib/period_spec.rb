# frozen_string_literal: true

require_relative "../spec_helper"
require "date"

require "period"
require "name"
require "person"
require "date_with_future"

RSpec.describe Period do
  let(:person) { Person.new(name: Name.new(first: "John", last: "Smith"), count: 1) }

  it "considers two periods with the same attributes equal" do
    period1 = Period.new(count: 1, house: House.representatives, division: "division1", party: "party1",
                         from_date: Date.new(2000, 1, 1), to_date: Date.new(2001, 1, 1),
                         from_why: "general_election", to_why: "defeated", person: person)
    period2 = Period.new(count: 1, house: House.representatives, division: "division1", party: "party1",
                         from_date: Date.new(2000, 1, 1), to_date: Date.new(2001, 1, 1),
                         from_why: "general_election", to_why: "defeated", person: person)
    expect(period1).to eq period2
  end

  it "considers two periods with different dates not equal" do
    period2 = Period.new(count: 1, house: House.representatives, division: "division1", party: "party1",
                         from_date: Date.new(2000, 1, 1), to_date: Date.new(2001, 1, 1),
                         from_why: "general_election", to_why: "defeated", person: person)
    period3 = Period.new(count: 1, house: House.representatives, division: "division1", party: "party1",
                         from_date: Date.new(2002, 1, 1), to_date: DateWithFuture.future,
                         from_why: "general_election", to_why: "current_member", person: person)
    expect(period2).not_to eq period3
  end

  it "raises on an invalid parameter" do
    expect {
      Period.new(count: 1, foo: "Blah", house: House.representatives, person: person)
    }.to raise_error(RuntimeError)
  end

  it "raises when count is missing" do
    expect {
      Period.new(house: House.representatives, person: person)
    }.to raise_error(RuntimeError)
  end
end

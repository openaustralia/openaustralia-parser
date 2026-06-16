# frozen_string_literal: true

require_relative "../spec_helper"
require "people_csv_reader"

RSpec.describe PeopleCSVReader do
  it "reads Sophie Mirabella's record correctly" do
    # It doesn't matter if other classes are instantiated first ...
    john_doe = Person.new(name: 'John Doe', count: 123)
    john_doe.add_period(house: House.representatives, from_date: Date.new(2001, 11, 10), to_date: Date.new(2013, 9, 7),
                   from_why: "general_election", to_why: "defeated",
                   division: "Indi", state: "Victoria", party: "Liberal Party", count: 383)
    john_doe.add_minister_position(count: 1401, from_date: Date.new(2011, 3, 3), to_date: Date.new(2013, 9, 18),
                              position: "Shadow Minister for Innovation, Industry and Science")

    ref = Person.new(
      name: Name.new(first: "Sophie", last: "Mirabella"),
      alternate_names: [Name.new(first: "Sophie", last: "Panopoulos")],
      count: 461, aph_id: "00AMU"
    )
    ref.add_period(house: House.representatives, from_date: Date.new(2001, 11, 10), to_date: Date.new(2013, 9, 7),
                   from_why: "general_election", to_why: "defeated",
                   division: "Indi", state: "Victoria", party: "Liberal Party", count: 383)
    ref.add_minister_position(count: 1401, from_date: Date.new(2011, 3, 3), to_date: Date.new(2013, 9, 18),
                              position: "Shadow Minister for Innovation, Industry and Science")
    ref.add_minister_position(count: 1688, from_date: Date.new(2008, 9, 22), to_date: Date.new(2009, 12, 8),
                              position: "Shadow Minister for Early Childhood Education, Childcare, Women and Youth")
    ref.add_minister_position(count: 1689, from_date: Date.new(2010, 9, 14), to_date: Date.new(2013, 9, 18),
                              position: "Shadow Minister for Innovation, Industry and Science")
    ref.add_minister_position(count: 1690, from_date: Date.new(2009, 12, 8), to_date: Date.new(2010, 9, 14),
                              position: "Shadow Minister for Innovation, Industry, Science and Research")
    ref.add_minister_position(count: 1691, from_date: Date.new(2007, 12, 6), to_date: Date.new(2008, 9, 22),
                              position: "Shadow Parliamentary Secretary for Local Government")


    people = PeopleCSVReader.read_members
    PeopleCSVReader.read_all_ministers(people)
    sophie_mirabella = people.find_person_by_name(Name.new(first: "Sophie", last: "Mirabella"))

    expect(sophie_mirabella).to eq ref
    # Explicitly check other properties since person.eq only checks id and periods
    expect(sophie_mirabella.person_count).to eq ref.person_count
    expect(sophie_mirabella.name).to eq ref.name
    expect(sophie_mirabella.alternate_names).to eq ref.alternate_names
    expect(sophie_mirabella.minister_positions.to_yaml).to eq ref.minister_positions.to_yaml
    expect(sophie_mirabella.birthday).to eq ref.birthday
    expect(sophie_mirabella.aph_id).to eq ref.aph_id
  end
end

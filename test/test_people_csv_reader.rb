$:.unshift "#{File.dirname(__FILE__)}/../lib"

require "test/unit"

require "people_csv_reader"

class TestPeopleCSVReader < Test::Unit::TestCase
  def test_sophie_mirabella
    ref = Person.new(
      name: Name.new(first: "Sophie", last: "Mirabella"),
      alternate_names: [Name.new(first: "Shophie", last: "Panopoulos")],
      count: 461, aph_id: "00AMU"
    )
    ref.add_period(house: House.representatives, from_date: Date.new(2001, 11, 10), to_date: Date.new(2013, 9, 7),
                   from_why: "general_election", to_why: "defeated",
                   division: "Indi", state: "Victoria", party: "Liberal Party", count: 383)
    ref.add_minister_position(count: 1441, from_date: Date.new(2007, 12, 6), to_date: Date.new(2008, 9, 22),
                              position: "Shadow Parliamentary Secretary for Local Government")
    ref.add_minister_position(count: 1440, from_date: Date.new(2009, 12, 8), to_date: Date.new(2010, 9, 14),
                              position: "Shadow Minister for Innovation, Industry, Science and Research")
    ref.add_minister_position(count: 1439, from_date: Date.new(2010, 9, 14), to_date: Date.new(2013, 9, 18),
                              position: "Shadow Minister for Innovation, Industry and Science")
    ref.add_minister_position(count: 1438, from_date: Date.new(2008, 9, 22), to_date: Date.new(2009, 12, 8),
                              position: "Shadow Minister for Early Childhood Education, Childcare, Women and Youth")
    ref.add_minister_position(count: 1161, from_date: Date.new(2011, 3, 3), to_date: Date.new(2013, 9, 18),
                              position: "Shadow Minister for Innovation, Industry and Science")

    people = PeopleCSVReader.read_members
    PeopleCSVReader.read_all_ministers(people)
    sophie_mirabella = people.find_person_by_name(Name.new(first: "Sophie", last: "Mirabella"))

    assert_equal(ref, sophie_mirabella)
  end
end

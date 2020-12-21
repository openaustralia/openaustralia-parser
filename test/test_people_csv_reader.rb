$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'test/unit'

require 'people_csv_reader'

class TestPeopleCSVReader < Test::Unit::TestCase
  def test_sophie_mirabella
    ref = Person.new(:name => Name.new(:first => "Sophie", :last => "Mirabella"), :count => 461)
    ref.add_period(:house => House.representatives, :from_date => Date.new(2001, 11, 10), :to_date => DateWithFuture.future,
      :from_why => "general_election", :to_why => "still_in_office",
      :division => "Indi", :state => "Victoria", :party => "Liberal Party", :count => 383)
    ref.add_minister_position(:count => 790, :from_date => Date.new(2007,12,6), :to_date => DateWithFuture.future,
      :position => "Shadow Parliamentary Secretary for Local Government")

    people = PeopleCSVReader.read_members
    PeopleCSVReader.read_all_ministers(people)
    sophie_mirabella = people.find_person_by_name(Name.new(:first => "Sophie", :last => "Mirabella"))

    assert_equal(ref, sophie_mirabella)
  end
end

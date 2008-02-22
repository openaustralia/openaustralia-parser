$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'test/unit'

require 'people_csv_reader'

class TestPeopleCSVReader < Test::Unit::TestCase
  # By resetting the id counters before every test we can ensure that the id's will be consistent
  def setup
    Person.reset_id_counter
    HousePeriod.reset_id_counter
  end
  
  def test_sophie_mirabella
    people = PeopleCSVReader.read("#{File.dirname(__FILE__)}/../data/house_members.csv")
    sophie_mirabella = people.find_person_by_name(Name.new(:first => "Sophie", :last => "Mirabella"))
    
    ref = Person.new(10319)
    ref.add_house_period(:name => Name.new(:first => "Sophie", :last => "Mirabella"),
      :from_date => Date.new(2001, 11, 10), :to_date => Date.new(9999, 12, 31),
      :from_why => "general_election", :to_why => "current_member",
      :division => "Indi", :party => "LIB", :id => 376)

    assert_equal(ref, sophie_mirabella)
  end
end
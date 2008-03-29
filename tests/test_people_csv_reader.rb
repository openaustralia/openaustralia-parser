$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'test/unit'

require 'people_csv_reader'

class TestPeopleCSVReader < Test::Unit::TestCase
  # By resetting the id counters before every test we can ensure that the id's will be consistent
  def setup
    Person.reset_id_counter
    Period.reset_id_counter
  end
  
  def test_sophie_mirabella
    people = PeopleCSVReader.read("#{File.dirname(__FILE__)}/../data/members.csv",
      "#{File.dirname(__FILE__)}/../data/ministers_new.csv")
    sophie_mirabella = people.find_person_by_name(Name.new(:first => "Sophie", :last => "Mirabella"))
    
    ref = Person.new(Name.new(:first => "Sophie", :last => "Mirabella"), Id.new("uk.org.publicwhip/person/", 10461))
    ref.add_house_period(:from_date => Date.new(2001, 11, 10), :to_date => DateWithFuture.future,
      :from_why => "general_election", :to_why => "current_member",
      :division => "Indi", :party => "LIB", :id => Id.new("uk.org.publicwhip/member/", 376))

    assert_equal(ref, sophie_mirabella)
  end
end
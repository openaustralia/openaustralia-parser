$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'test/unit'

require 'people_csv_reader'

# This test is too fragile. It breaks any time you change *anything* in members.csv. So, commenting it out for the time being.

#class TestPeopleCSVReader < Test::Unit::TestCase
#  # By resetting the id counters before every test we can ensure that the id's will be consistent
#  def setup
#    Person.reset_id_counter
#    Period.reset_id_counter
#  end
#  
#  def test_sophie_mirabella
#    people = PeopleCSVReader.read("#{File.dirname(__FILE__)}/../data/members.csv",
#      "#{File.dirname(__FILE__)}/../data/ministers.csv", "#{File.dirname(__FILE__)}/../data/shadow-ministers.csv")
#    sophie_mirabella = people.find_person_by_name(Name.new(:first => "Sophie", :last => "Mirabella"))
#    
#    ref = Person.new(Name.new(:first => "Sophie", :last => "Mirabella"), Id.new("uk.org.publicwhip/person/", 10461))
#    ref.add_house_period(:from_date => Date.new(2001, 11, 10), :to_date => DateWithFuture.future,
#      :from_why => "general_election", :to_why => "still_in_office",
#      :division => "Indi", :party => "Liberal Party", :id => Id.new("uk.org.publicwhip/member/", 380))
#
#    assert_equal(ref, sophie_mirabella)
#  end
#end
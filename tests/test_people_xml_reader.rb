$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'test/unit'
require 'date'

require 'person'
require 'name'
require 'people'

class TestPeopleXMLReader < Test::Unit::TestCase
  def test_write_followed_by_read
    # Make two people with a couple of periods in the house
    john_smith = Person.new(Name.new(:first => "John", :last => "Smith"))
    john_smith.add_house_period(:division => "division1", :party => "party1",
      :from_date => Date.new(2000, 1, 1), :to_date => Date.new(2001, 1, 1),
      :from_why => "general_election", :to_why => "defeated")
    john_smith.add_house_period(:division => "division1", :party => "party1",
        :from_date => Date.new(2002, 1, 1), :to_date => Date.new(9999, 1, 1),
        :from_why => "general_election", :to_why => "current_member")
    henry_jones = Person.new(Name.new(:first => "Henry", :last => "Jones"))
    henry_jones.add_house_period(:division => "division2", :party => "party2",
      :from_date => Date.new(2000, 1, 1), :to_date => Date.new(2001, 1, 1),
      :from_why => "general_election", :to_why => "defeated")
    henry_jones.add_house_period(:division => "division2", :party => "party2",
        :from_date => Date.new(2002, 1, 1), :to_date => Date.new(2003, 1, 1),
        :from_why => "general_election", :to_why => "defeated")
  
    people = People.new
    people << john_smith
    people << henry_jones
    
    # Write the XML
    system('mkdir -p test_output')
    people.write_people_xml('test_output/people.xml')
    people.write_members_xml('test_output/members.xml')
    
    # Read the XML back in
    people2 = People.read_xml('test_output/people.xml', 'test_output/members.xml')
    
    assert_equal(people, people2)
    
    system('rm -rf test_output')
  end
end
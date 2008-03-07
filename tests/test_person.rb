$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'test/unit'
require 'date'

require 'person'
require 'name'

class TestPerson < Test::Unit::TestCase
  def test_equality
    john_smith1 = Person.new(Name.new(:first => "John", :last => "Smith"))
    john_smith1.add_house_period(:division => "division1", :party => "party1",
      :from_date => Date.new(2000, 1, 1), :to_date => Date.new(2001, 1, 1),
      :from_why => "general_election", :to_why => "defeated")
    # Give john_smith2 the same id as john_smith1
    john_smith2 = Person.new(Name.new(:first => "John", :last => "Smith"), john_smith1.id)
    john_smith2.add_house_period(:division => "division1", :party => "party1",
        :from_date => Date.new(2000, 1, 1), :to_date => Date.new(2001, 1, 1),
        :from_why => "general_election", :to_why => "defeated",
        :id => john_smith1.periods[0].id)
    
    henry_jones = Person.new(Name.new(:first => "Henry", :last => "Jones"))
    henry_jones.add_house_period(:division => "division2", :party => "party2",
      :from_date => Date.new(2000, 1, 1), :to_date => Date.new(2001, 1, 1),
      :from_why => "general_election", :to_why => "defeated")

    assert_equal(john_smith1, john_smith2)
    assert_not_equal(henry_jones, john_smith2)
  end
  
  def test_latest_house_period
    # John Smith got a doctorate on Jan 1 2001
    john_smith = Name.new(:first => "John", :last => "Smith")
    person = Person.new(john_smith)
    
    # Adding the periods *not* in chronological order
    person.add_house_period(:from_date => Date.new(2001, 1, 1), :to_date => Date.new(2002, 1, 1))
    person.add_house_period(:from_date => Date.new(2000, 1, 1), :to_date => Date.new(2001, 1, 1))
    
    assert_equal(Date.new(2002, 1, 1), person.latest_period.to_date)
  end
  
  def test_find_house_period_by_id
    person = Person.new(Name.new(:first => "John", :last => "Smith"))
    person.add_house_period(:id => 1)
    person.add_house_period(:id => 2)
    assert_equal(1, person.find_period_by_id(1).id)
    assert_equal(nil, person.find_period_by_id(3))
    
    assert(person.has_period_with_id?(1))
    assert(!person.has_period_with_id?(3))
  end
  
end
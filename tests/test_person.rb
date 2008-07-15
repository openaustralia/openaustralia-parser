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
    john_smith2 = Person.new(Name.new(:first => "John", :last => "Smith"), john_smith1.person_count)
    john_smith2.add_house_period(:division => "division1", :party => "party1",
        :from_date => Date.new(2000, 1, 1), :to_date => Date.new(2001, 1, 1),
        :from_why => "general_election", :to_why => "defeated",
        :count => john_smith1.periods[0].count)
    
    henry_jones = Person.new(Name.new(:first => "Henry", :last => "Jones"))
    henry_jones.add_house_period(:division => "division2", :party => "party2",
      :from_date => Date.new(2000, 1, 1), :to_date => Date.new(2001, 1, 1),
      :from_why => "general_election", :to_why => "defeated")

    assert_equal(john_smith1, john_smith2)
    assert_not_equal(henry_jones, john_smith2)
  end
end
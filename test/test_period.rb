$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'test/unit'
require 'date'

require 'period'
require 'name'
require 'person'
require 'date_with_future'

class TestPeriod < Test::Unit::TestCase
  def setup
    @person = Person.new(:name => Name.new(:first => "John", :last => "Smith"), :count => 1)
  end
  
  def test_equality
    period1 = Period.new(:count => 1, :house => House.representatives, :division => "division1", :party => "party1",
      :from_date => Date.new(2000, 1, 1), :to_date => Date.new(2001, 1, 1),
      :from_why => "general_election", :to_why => "defeated", :person => @person)
    period2 = Period.new(:count => 1, :house => House.representatives, :division => "division1", :party => "party1",
        :from_date => Date.new(2000, 1, 1), :to_date => Date.new(2001, 1, 1),
        :from_why => "general_election", :to_why => "defeated", :person => @person)    
    period3 = Period.new(:count => 1, :house => House.representatives, :division => "division1", :party => "party1",
            :from_date => Date.new(2002, 1, 1), :to_date => DateWithFuture.future,
            :from_why => "general_election", :to_why => "current_member", :person => @person)

    assert_equal(period1, period2)
    assert_not_equal(period2, period3)
  end
  
  def test_invalid_parameter
    # :foo isn't valid
    assert_raises(RuntimeError) { Period.new(:count => 1, :foo => "Blah", :house => House.representatives, :person => @person) }
    # :count is missing
    assert_raises(RuntimeError) { Period.new(:house => House.representatives, :person => @person) }
  end
end
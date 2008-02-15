$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'test/unit'
require 'date'

require 'house_period'

class TestHousePeriod < Test::Unit::TestCase
  def test_equality
    period1 = HousePeriod.new(:division => "division1", :party => "party1",
      :from_date => Date.new(2000, 1, 1), :to_date => Date.new(2001, 1, 1),
      :from_why => "general_election", :to_why => "defeated")
    # Make period2 and period1 the same by giving them the same id
    period2 = HousePeriod.new(:id => period1.id, :division => "division1", :party => "party1",
        :from_date => Date.new(2000, 1, 1), :to_date => Date.new(2001, 1, 1),
        :from_why => "general_election", :to_why => "defeated")
    
    period3 = HousePeriod.new(:division => "division1", :party => "party1",
            :from_date => Date.new(2002, 1, 1), :to_date => Date.new(9999, 1, 1),
            :from_why => "general_election", :to_why => "current_member")
    assert_equal(period1, period2)
    assert_not_equal(period2, period3)
  end
end
$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'test/unit'
require 'people'
#require 'date'

class TestPeople < Test::Unit::TestCase
  def test_speaker
    people = People.read_csv("../data/members.csv", "../data/ministers.csv")
    assert_equal("David Peter Maxwell Hawker", people.house_speaker(Date.new(2007,10,1)).person.name.full_name)
  end
end
$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'test/unit'
require 'people'

class TestPeople < Test::Unit::TestCase
  def test_speaker
    people = People.read_members_csv("#{File.dirname(__FILE__)}/../data/members.csv")
    people.read_ministers_csv("#{File.dirname(__FILE__)}/../data/ministers.csv")
    member = people.house_speaker(Date.new(2007, 10, 1))
    assert_equal("David Peter Maxwell Hawker", member.person.name.full_name)
    assert(member.house_speaker?)
    
    member = people.deputy_house_speaker(Date.new(2008, 2, 12))
    assert_equal("Ms Anna Elizabeth Burke", member.person.name.full_name)
    assert(member.deputy_house_speaker?)
  end
end
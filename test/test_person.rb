$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'test/unit'
require 'date'

require 'person'
require 'name'

class TestPerson < Test::Unit::TestCase
  def test_equality
    john_smith1 = Person.new(name: Name.new(first: "John", last: "Smith"), count: 1)
    john_smith1.add_period(house: House.representatives, division: "division1", party: "party1",
                           from_date: Date.new(2000, 1, 1), to_date: Date.new(2001, 1, 1),
                           from_why: "general_election", to_why: "defeated", count: 1)
    # Give john_smith2 the same id as john_smith1
    john_smith2 = Person.new(name: Name.new(first: "John", last: "Smith"), count: 1)
    john_smith2.add_period(house: House.representatives, division: "division1", party: "party1",
                           from_date: Date.new(2000, 1, 1), to_date: Date.new(2001, 1, 1),
                           from_why: "general_election", to_why: "defeated", count: 1)

    henry_jones = Person.new(name: Name.new(first: "Henry", last: "Jones"), count: 2)
    henry_jones.add_period(house: House.representatives, division: "division2", party: "party2",
                           from_date: Date.new(2000, 1, 1), to_date: Date.new(2001, 1, 1),
                           from_why: "general_election", to_why: "defeated", count: 2)

    assert_equal(john_smith1, john_smith2)
    assert_not_equal(henry_jones, john_smith2)
  end

  def test_multiple_names
    john_smith = Name.new(first: "John", last: "Smith")
    jack_smith = Name.new(first: "Jack", last: "Smith")
    person = Person.new(count: 1, name: john_smith, alternate_names: [jack_smith])
    assert_equal(john_smith, person.name)
    assert_equal([jack_smith], person.alternate_names)
    assert_equal([john_smith, jack_smith], person.all_names)
  end

  def test_name_matches
    john_smith = Name.new(first: "John", last: "Smith")
    jack_smith = Name.new(first: "Jack", last: "Smith")
    henry_smith = Name.new(first: "Henry", last: "Smith")
    person = Person.new(count: 1, name: john_smith, alternate_names: [jack_smith])
    assert(person.name_matches?(john_smith))
    assert(person.name_matches?(jack_smith))
    assert(!person.name_matches?(henry_smith))
  end
end

$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'test/unit'

require 'people_csv_reader'

class TestPeopleCSVReader < Test::Unit::TestCase
  def test_sophie_mirabella
    people = PeopleCSVReader.read("#{File.dirname(__FILE__)}/../data/house_members.csv")
    sophie_mirabella = people.find_person_by_name(Name.new(:first => "Sophie", :last => "Mirabella"))
    
    # Ignoring id's in test of equality by assigning them to be the same
    ref = Person.new(sophie_mirabella.id)
    ref.add_house_period(:name => Name.new(:first => "Sophie", :last => "Mirabella"),
      :from_date => Date.new(2001, 11, 10), :to_date => Date.new(9999, 12, 31),
      :from_why => "general_election", :to_why => "current_member",
      :division => "Indi", :party => "LIB", :id => sophie_mirabella.house_periods[0].id)

    assert_equal(ref, sophie_mirabella)
  end
end
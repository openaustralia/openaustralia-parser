$:.unshift "#{File.dirname(__FILE__)}/../lib"

require "test/unit"
require 'spec'

require "people"

describe People do
  before :each do
    # TODO: This is slow
    @people = PeopleCSVReader.read_members
    PeopleCSVReader.read_all_ministers(@people)
  end
  
  it "can list all the electoral divisions for all the members" do
    people = People.new

    people << Person.new(:name => Name.new(:first => "John", :last => "Smith"), :count => 1)
    people.last.add_period(:house => House.representatives, :division => "A", :count => 1)
    
    people << Person.new(:name => Name.new(:first => "Joe", :last => "Smith"), :count => 2)
    people.last.add_period(:house => House.representatives, :division => "B", :count => 2)

    people << Person.new(:name => Name.new(:first => "Henry", :last => "Smith"), :count => 3)
    people.last.add_period(:house => House.representatives, :division => "C", :count => 3)
    
    people.divisions.should == %w{A B C}
  end
  
  it "knows who the speaker is" do
    member = @people.house_speaker(Date.new(2007, 10, 1))
    member.person.name.full_name.should == "David Peter Maxwell Hawker"
    member.should be_house_speaker
  end

  it "knows who the deputy speakers is" do
    member = @people.deputy_house_speaker(Date.new(2008, 2, 12))
    member.person.name.full_name.should == "Ms Anna Elizabeth Burke"
    member.should be_deputy_house_speaker
  end
end

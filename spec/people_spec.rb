$:.unshift "#{File.dirname(__FILE__)}/../lib"

require "test/unit"
require 'spec'

require "people"

describe People do
  before :each do
    @people = People.new

    @people << Person.new(:name => Name.new(:first => "John", :last => "Smith"), :count => 1)
    @people.last.add_period(:from_date => Date.new(2000, 1, 1), :to_date => Date.new(2001, 1, 1),
      :house => House.representatives, :division => "A", :party => "SPK", :count => 1)
    
    @people << Person.new(:name => Name.new(:first => "Joe", :last => "Smith"), :count => 2)
    @people.last.add_period(:from_date => Date.new(2001, 1, 1), :to_date => Date.new(2002, 1, 1),
      :house => House.representatives, :division => "B", :party => "SPK", :count => 2)

    @people << Person.new(:name => Name.new(:first => "Henry", :last => "Smith"), :count => 3)
    @people.last.add_period(:from_date => Date.new(2000, 1, 1), :to_date => Date.new(2001, 1, 1),
      :house => House.representatives, :division => "C", :party => "CWM", :count => 3)
  end
  
  it "can list all the electoral divisions for all the members" do    
    @people.divisions.should == %w{A B C}
  end
  
  it "knows who the speaker is" do
    member = @people.house_speaker(Date.new(2000, 6, 1))
    member.person.name.full_name.should == "John Smith"
    member.should be_house_speaker
  end

  it "knows who the deputy speakers is" do
    member = @people.deputy_house_speaker(Date.new(2000, 6, 1))
    member.person.name.full_name.should == "Henry Smith"
    member.should be_deputy_house_speaker
  end
end

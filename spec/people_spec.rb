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

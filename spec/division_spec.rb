$:.unshift "#{File.dirname(__FILE__)}/../lib"

require "test/unit"
require 'spec'

require "division"
require 'house'

# The Division class knows how to output XML
describe Division do
  it "has the id in the correct form" do
    # Time, URL, Major count, Minor count, Date, and house
    division = Division.new("10:11:00", "http://foo/link", 10, 2, Date.new(2008, 2, 1), House.representatives)
    division.id.should == "uk.org.publicwhip/debate/2008-02-01.10.2"
  end
end
  

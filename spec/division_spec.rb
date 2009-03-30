$:.unshift "#{File.dirname(__FILE__)}/../lib"

require "test/unit"
require 'spec'

require "division"
require 'house'

# The Division class knows how to output XML
describe Division do
  it "has the id in the correct form" do
    # Date, Major count, Minor count, and house
    division = Division.new(Date.new(2008, 2, 1), 10, 2, House.representatives)
    division.id.should == "uk.org.publicwhip/debate/2008-02-01.10.2"
  end
end
  

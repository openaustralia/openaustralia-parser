$:.unshift "#{File.dirname(__FILE__)}/../lib"

require "test/unit"

require "name"

describe Name do
  describe '.last_title_first' do
    it 'parses non-hypenated first names' do
      name = Name.last_title_first("  BROWN  ,   Robert   (Bob)   James  ")
      name.first.should == 'Robert'
      name.middle.should == 'James'
      name.last.should == 'Brown'
    end

    it 'parses hyphenated first names' do
      name = Name.last_title_first("  KELLY  , the Hon.   De  -  Anne     Margaret  ")
      name.first.should == 'De-Anne'
      name.middle.should == 'Margaret'
      name.last.should == 'Kelly'
    end
  end
end

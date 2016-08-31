$:.unshift "#{File.dirname(__FILE__)}/../lib"

require "test/unit"

require "name"

describe Name do
  describe '.initials' do
    it "returns the string with stops deleted if it includes a fullstop" do
      expect(Name.initials("X.S")).to eq "XS"
      expect(Name.initials("X.S.")).to eq "XS"
      # Do we really want this?
      expect(Name.initials("John.Lawrence")).to eq "JohnLawrence"
    end

    it "returns the full string if it is all-caps" do
      expect(Name.initials("XS")).to eq "XS"
      expect(Name.initials("ALLCAPSWHENYASPELLMANAME")).to eq "ALLCAPSWHENYASPELLMANAME"
      expect(Name.initials("YOUNG")).to eq "YOUNG"
    end

    it "returns the string if it is all non-letter characters" do
      expect(Name.initials("1234")).to eq "1234"
    end

    it "returns nil if it is a specific non-letter character" do
      expect(Name.initials("-")).to eq nil
    end

    it "returns nil if it is a specific two letter name (Ed or Jo)" do
      expect(Name.initials("Ed")).to eq nil
      expect(Name.initials("Jo")).to eq nil
      expect(Name.initials("Xi")).not_to eq nil
    end

    it "returns the string if it is a specific three letter string (DJC or DGH)" do
      expect(Name.initials("DJC")).to eq "DJC"
      expect(Name.initials("DGH")).to eq "DGH"
    end

    it "returns the string if it is two characters or shorter" do
      expect(Name.initials("xs")).to eq "xs"
      expect(Name.initials("Ah")).to eq "Ah"
      expect(Name.initials("1h")).to eq "1h"
      expect(Name.initials("b")).to eq "b"
      expect(Name.initials("")).to eq ""
    end

    it "returns nil if it is longer than two character" do
      expect(Name.initials("AMcH")).to eq nil
      expect(Name.initials("Zhang")).to eq nil
      expect(Name.initials("Young")).to eq nil
    end
  end

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

    it 'parses all-caps, hyphenated last names' do
      name = Name.last_title_first("  HANSON  -  YOUNG  ,   Sarah   Coral")
      name.first.should == 'Sarah'
      name.middle.should == 'Coral'
      name.last.should == 'Hanson-Young'
    end
  end
end

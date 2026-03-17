# frozen_string_literal: true

require_relative "../spec_helper"
require "name"

RSpec.describe Name do
  describe ".initials" do
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

  describe ".last_title_first" do
    it "correctly handles a title and a middle name" do
      name = Name.last_title_first("MARTIN, Dr. Fiona Barbouttis")
      expect(name.title).to eq "Dr."
      expect(name.first).to eq "Fiona"
      expect(name.middle).to eq "Barbouttis"
      expect(name.last).to eq "Martin"
    end

    it "parses names with no middle names" do
      name = Name.last_title_first("  ALY  ,   Anne  ")
      expect(name.first).to eq "Anne"
      expect(name.middle).to eq ""
      expect(name.last).to eq "Aly"
    end

    it "parses names with middle names" do
      name = Name.last_title_first("  BAKER  ,   Mark     Horden  ")
      expect(name.first).to eq "Mark"
      expect(name.middle).to eq "Horden"
      expect(name.last).to eq "Baker"
    end

    it "parses names with titles" do
      name = Name.last_title_first("  BACK  , Dr   Christopher     John  ")
      expect(name.title).to eq "Dr"
      expect(name.first).to eq "Christopher"
      expect(name.middle).to eq "John"
      expect(name.last).to eq "Back"
    end

    it "parses names with titles and brackets" do
      name = Name.last_title_first("  BAILEY  , the Hon. Frances (  Fran  )   Esther  ")
      expect(name.title).to eq "the Hon."
      expect(name.first).to eq "Frances"
      expect(name.middle).to eq "Esther"
      expect(name.last).to eq "Bailey"
    end

    it "parses non-hyphenated first names" do
      name = Name.last_title_first("  BROWN  ,   Robert   (Bob)   James  ")
      expect(name.first).to eq "Robert"
      expect(name.middle).to eq "James"
      expect(name.last).to eq "Brown"
    end

    it "parses hyphenated first names" do
      name = Name.last_title_first("  KELLY  , the Hon.   De  -  Anne     Margaret  ")
      expect(name.title).to eq "the Hon."
      expect(name.first).to eq "De-Anne"
      expect(name.middle).to eq "Margaret"
      expect(name.last).to eq "Kelly"
    end

    it "parses hyphenated last names (Hanson-Young)" do
      name = Name.last_title_first("  HANSON  -  YOUNG  ,   Sarah   Coral")
      expect(name.first).to eq "Sarah"
      expect(name.middle).to eq "Coral"
      expect(name.last).to eq "Hanson-Young"
    end

    it "parses hyphenated last names (Kakoschke-Moore)" do
      name = Name.last_title_first("  KAKOSCHKE  -  MOORE  ,   Skye  ")
      expect(name.first).to eq "Skye"
      expect(name.middle).to eq ""
      expect(name.last).to eq "Kakoschke-Moore"
    end
  end

  describe ".new" do
    it "creates a name with the given attributes" do
      matthew = Name.new(first: "Matthew", middle: "Noah", last: "Landauer")
      expect(matthew.first).to eq "Matthew"
      expect(matthew.middle).to eq "Noah"
      expect(matthew.last).to eq "Landauer"
    end

    it "raises on unknown parameters" do
      expect { Name.new(first: "foo", blah: "dibble") }.to raise_error(RuntimeError)
    end

    it "considers names with the same attributes equal" do
      expect(Name.new(last: "Landauer", middle: "Noah", first: "Matthew")).to eq \
        Name.new(first: "Matthew", middle: "Noah", last: "Landauer")
    end

    it "considers names with different attributes not equal" do
      expect(Name.new(first: "Matthew", middle: "Noah", last: "Landauer")).not_to eq \
        Name.new(last: "Landauer")
    end

    it "capitalises Irish names correctly" do
      expect(Name.new(last: "o'connor").last).to eq "O'Connor"
    end

    it "capitalises Scottish names correctly" do
      expect(Name.new(last: "mcmullan").last).to eq "McMullan"
    end

    it "capitalises D'Ath correctly" do
      expect(Name.new(last: "d'ath").last).to eq "D'Ath"
    end

    it "capitalises double-barrelled names correctly" do
      expect(Name.new(last: "hanson-young").last).to eq "Hanson-Young"
    end

    it "capitalises middle names with Mc prefix" do
      expect(Name.new(middle: "mccahon").middle).to eq "McCahon"
    end
  end

  describe ".last_title_first (TestName cases)" do
    it "parses a simple name" do
      expect(Name.last_title_first("Gash Joanna")).to eq Name.new(first: "Joanna", last: "Gash")
    end

    it "is case insensitive" do
      expect(Name.last_title_first("GASH joanna")).to eq Name.new(first: "Joanna", last: "Gash")
    end

    it "parses a middle name" do
      expect(Name.last_title_first("Albanese Anthony Norman")).to eq \
        Name.new(last: "Albanese", first: "Anthony", middle: "Norman")
    end

    it "parses two middle names" do
      expect(Name.last_title_first("Albanese Anthony Norman Peter")).to eq \
        Name.new(last: "Albanese", first: "Anthony", middle: "Norman peter")
    end

    it "parses 'the Hon.' title" do
      expect(Name.last_title_first("Baird the Hon. Bruce George")).to eq \
        Name.new(last: "Baird", title: "the Hon.", first: "Bruce", middle: "George")
    end

    it "parses initials only (JF)" do
      expect(Name.last_title_first("Johnson, JF")).to eq Name.new(last: "Johnson", initials: "JF")
    end

    it "parses initials only (JFK)" do
      expect(Name.last_title_first("Johnson, JFK")).to eq Name.new(last: "Johnson", initials: "JFK")
    end

    it "parses a nickname" do
      expect(Name.last_title_first("ABBOTT, the Hon. Anthony (Tony) John")).to eq \
        Name.new(last: "Abbott", title: "the Hon.", first: "Anthony", middle: "John")
    end

    it "parses Dr title" do
      expect(Name.last_title_first("EMERSON, Dr Craig Anthony")).to eq \
        Name.new(last: "Emerson", title: "Dr", first: "Craig", middle: "Anthony")
    end

    it "returns informal name without title" do
      expect(Name.new(first: "Matthew", last: "Landauer", title: "Dr").informal_name).to eq "Matthew Landauer"
    end

    it "returns full name including title" do
      expect(Name.new(last: "Abbott", title: "the Hon.", first: "Anthony", middle: "John").full_name).to eq \
        "the Hon. Anthony John Abbott"
    end

    it "parses Stott Despoja (two unhyphenated last names)" do
      expect(Name.last_title_first("STOTT DESPOJA, Natasha Jessica")).to eq \
        Name.new(last: "Stott Despoja", first: "Natasha", middle: "Jessica")
    end

    it "parses post title AM" do
      name = Name.last_title_first("COMBET, the Hon. Gregory (Greg) Ivan, AM")
      expect(name.last).to eq "Combet"
      expect(name.title).to eq "the Hon."
      expect(name.first).to eq "Gregory"
      expect(name.middle).to eq "Ivan"
      expect(name.post_title).to eq "AM"
    end

    it "parses post title MBE" do
      expect(Name.last_title_first("Smith, John, MBE")).to eq \
        Name.new(first: "John", last: "Smith", post_title: "MBE")
    end

    it "parses post title QC" do
      expect(Name.last_title_first("Smith, John, QC")).to eq \
        Name.new(first: "John", last: "Smith", post_title: "QC")
    end

    it "parses post title OBE" do
      expect(Name.last_title_first("Smith, John, OBE")).to eq \
        Name.new(first: "John", last: "Smith", post_title: "OBE")
    end

    it "parses post title KSJ" do
      expect(Name.last_title_first("Smith, John, KSJ")).to eq \
        Name.new(first: "John", last: "Smith", post_title: "KSJ")
    end

    it "parses post title JP" do
      expect(Name.last_title_first("Smith, John, JP")).to eq \
        Name.new(first: "John", last: "Smith", post_title: "JP")
    end

    it "parses two post titles" do
      expect(Name.last_title_first("WILLIAMS, the Hon. Daryl Robert, AM, QC")).to eq \
        Name.new(last: "Williams", title: "the Hon.", first: "Daryl", middle: "Robert", post_title: "AM QC")
    end

    it "parses Ian Sinclair (Rt Hon.)" do
      expect(Name.last_title_first("SINCLAIR, the Rt Hon. Ian Mccahon")).to eq \
        Name.new(last: "Sinclair", title: "the Rt Hon.", first: "Ian", middle: "McCahon")
    end

    it "parses Lady Bjelke-Petersen" do
      expect(Name.last_title_first("BJELKE-PETERSEN, Lady (Florence Isabel)")).to eq \
        Name.new(last: "Bjelke-Petersen", title: "Lady")
    end

    it "parses nickname after middle names" do
      expect(Name.last_title_first("MACDONALD, the Hon. John Alexander Lindsay (Sandy)")).to eq \
        Name.new(last: "Macdonald", title: "the Hon.", first: "John", middle: "Alexander Lindsay")
    end

    it "parses Hon. (without 'the')" do
      name = Name.last_title_first("DEBUS, Hon. Robert (Bob) John")
      expect(name.last).to eq "Debus"
      expect(name.title).to eq "Hon."
      expect(name.first).to eq "Robert"
      expect(name.middle).to eq "John"
    end

    it "parses initials at end with fullstops (MAJ)" do
      expect(Name.last_title_first("Vaile, M.A.J.")).to eq Name.new(initials: "MAJ", last: "Vaile")
    end

    it "parses single initial at end with fullstop" do
      expect(Name.last_title_first("Turnbull, M.")).to eq Name.new(initials: "M", last: "Turnbull")
    end

    it "parses initials with spaces" do
      expect(Name.last_title_first("Wakelin, B. H.")).to eq Name.new(last: "Wakelin", initials: "BH")
    end

    it "parses initials with multiple fullstops" do
      expect(Name.last_title_first("Trood R.B..")).to eq Name.new(last: "Trood", initials: "RB")
    end

    it "returns empty name for empty string" do
      expect(Name.last_title_first("")).to eq Name.new({})
    end
  end

  describe ".title_first_last" do
    it "parses Dr John Smith" do
      expect(Name.title_first_last("Dr John Smith")).to eq Name.new(title: "Dr", first: "John", last: "Smith")
    end

    it "parses Dr Smith" do
      expect(Name.title_first_last("Dr Smith")).to eq Name.new(title: "Dr", last: "Smith")
    end

    it "parses Mr Smith" do
      expect(Name.title_first_last("Mr Smith")).to eq Name.new(title: "Mr", last: "Smith")
    end

    it "parses Mrs Smith" do
      expect(Name.title_first_last("Mrs Smith")).to eq Name.new(title: "Mrs", last: "Smith")
    end

    it "parses Ms Julie Smith" do
      expect(Name.title_first_last("Ms Julie Smith")).to eq Name.new(title: "Ms", first: "Julie", last: "Smith")
    end

    it "parses Ms Julie Sarah Marie Smith" do
      expect(Name.title_first_last("Ms Julie Sarah Marie Smith")).to eq \
        Name.new(title: "Ms", first: "Julie", middle: "Sarah Marie", last: "Smith")
    end

    it "parses Ed Husic (short first name)" do
      name = Name.title_first_last("Ed Husic")
      expect(name.last).to eq "Husic"
      expect(name.first).to eq "Ed"
    end

    it "handles non-breaking spaces" do
      nbsp = [160].pack("U")
      expect(Name.title_first_last("Mr#{nbsp}John#{nbsp}Smith")).to eq \
        Name.new(title: "Mr", first: "John", last: "Smith")
    end

    it "parses The Hon John Howard MP" do
      expect(Name.title_first_last("The Hon John Howard MP")).to eq \
        Name.new(title: "the Hon.", first: "John", last: "Howard", post_title: "MP")
    end

    it "parses Senator the Hon Nick Minchin" do
      expect(Name.title_first_last("Senator the Hon Nick Minchin")).to eq \
        Name.new(title: "Senator the Hon.", first: "Nick", last: "Minchin")
    end

    it "parses DJC Kerr (three-letter initials)" do
      expect(Name.title_first_last("DJC Kerr")).to eq Name.new(initials: "DJC", last: "Kerr")
    end

    it "parses LK Johnson (two-letter initials)" do
      expect(Name.title_first_last("LK Johnson")).to eq Name.new(initials: "LK", last: "Johnson")
    end

    it "parses Hon. DGH Adams" do
      expect(Name.title_first_last("Hon. DGH Adams")).to eq Name.new(title: "Hon.", initials: "DGH", last: "Adams")
      expect(Name.title_first_last("Hon. D.G.H. Adams")).to eq Name.new(title: "Hon.", initials: "DGH", last: "Adams")
    end

    it "parses Senator STOTT DESPOJA" do
      expect(Name.title_first_last("Senator STOTT DESPOJA")).to eq \
        Name.new(last: "Stott Despoja", title: "Senator")
    end

    it "parses Natasha Stott Despoja" do
      expect(Name.title_first_last("Natasha Stott Despoja")).to eq \
        Name.new(last: "Stott Despoja", first: "Natasha")
    end

    it "parses Dan John Van Manen initials" do
      expect(Name.title_first_last("Dan John Van Manen").real_initials).to eq "DJ"
    end

    it "returns empty name for empty string" do
      expect(Name.title_first_last("")).to eq Name.new({})
    end
  end

  describe "#matches?" do
    it "matches itself" do
      dr_john_smith = Name.new(title: "Dr", first: "John", last: "Smith")
      expect(dr_john_smith.matches?(dr_john_smith)).to be true
    end

    it "does not match a different first name" do
      expect(Name.new(title: "Dr", first: "John", last: "Smith").matches?(
               Name.new(first: "Peter", last: "Smith")
             )).to be false
    end

    it "does not match when there is no overlap" do
      expect(Name.new(last: "Smith").matches?(Name.new(title: "Dr", first: "John"))).to be false
    end

    it "matches with middle name missing from one side" do
      expect(Name.new(first: "Kim", middle: "William", last: "Wilkie").matches?(
               Name.new(first: "Kim", last: "Wilkie")
             )).to be true
    end

    it "matches with first initial" do
      l_johnson = Name.title_first_last("L Johnson")
      expect(Name.new(first: "Leonard", middle: "Keith", last: "Johnson").matches?(l_johnson)).to be true
      expect(Name.new(first: "Leslie", middle: "Royston", last: "Johnson").matches?(l_johnson)).to be true
      expect(Name.new(first: "Peter", middle: "Francis", last: "Johnson").matches?(l_johnson)).to be false
    end

    it "matches with two-letter middle initial" do
      lk_johnson = Name.title_first_last("LK Johnson")
      expect(Name.new(first: "Leonard", middle: "Keith", last: "Johnson").matches?(lk_johnson)).to be true
      expect(Name.new(first: "Leslie", middle: "Royston", last: "Johnson").matches?(lk_johnson)).to be false
      expect(lk_johnson.matches?(Name.new(first: "Leonard", middle: "Keith", last: "Johnson"))).to be true
    end
  end

  describe "#real_initials / #first_initial / #middle_initials" do
    it "computes real_initials" do
      expect(Name.new(first: "John", middle: "Edward Peter").real_initials).to eq "JEP"
      expect(Name.new(first: "Dan", middle: "John", last: "Van Manen").real_initials).to eq "DJ"
      expect(Name.new(initials: "MN").real_initials).to eq "MN"
    end

    it "computes first_initial" do
      expect(Name.new(first: "John", middle: "Edward Peter").first_initial).to eq "J"
      expect(Name.new(initials: "MN").first_initial).to eq "M"
    end

    it "computes middle_initials" do
      expect(Name.new(first: "John", middle: "Edward Peter").middle_initials).to eq "EP"
      expect(Name.new(initials: "MN").middle_initials).to eq "N"
    end
  end

  describe ".initials_with_fullstops" do
    it "strips fullstops from dotted initials" do
      expect(Name.initials_with_fullstops("D.G.H.")).to eq "DGH"
      expect(Name.initials_with_fullstops("A.B.")).to eq "AB"
      expect(Name.initials_with_fullstops("M.")).to eq "M"
      expect(Name.initials_with_fullstops("AB.")).to eq "AB"
    end

    it "returns nil for initials without trailing fullstop" do
      expect(Name.initials_with_fullstops("AB")).to be_nil
    end

    it "handles edge case of only dots" do
      expect(Name.initials_with_fullstops("..")).to eq ""
    end
  end
end

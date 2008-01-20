#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/.."

require 'member-parser'
require 'test/unit'

class TestMemberParser < Test::Unit::TestCase
  def setup
    @url = URI.parse("http://foo.co.uk")
    @source = File.join(File.dirname(__FILE__), "source")
  end
  
  def test_from_date_simple
      member = read_member("Kate_Ellis.html")
      assert_equal("2004-10-07", member.fromdate)
      assert_equal("general_election", member.fromwhy)        
  end
  
  #def test_former_member
  #  fromdate, fromwhy = MemberParser.parse_parliamentary_service_text(
  #    "elected to the house of representatives for longman, queensland, 1996, 1998, 2001 and 2004. " +
  #    "defeated at general elections 2007.")
  #  assert_equal("1994-11-19", fromdate)
  #  assert_equal("by_election", fromwhy)
  #end
  
  def test_elected_at_by_election
    fromdate, fromwhy = MemberParser.parse_parliamentary_service_text(
      "Elected to the House of Representatives for Aston, Victoria at by-election 14.7.2001 " +
      "vice PE Nugent (deceased). Re-elected 2001 and 2004.")
    assert_equal("2001-07-14", fromdate)
    assert_equal("by_election", fromwhy)
  end
  
  def test_elected_at_by_election_on
    fromdate, fromwhy = MemberParser.parse_parliamentary_service_text(
      "elected to the house of representatives for kooyong, victoria, at by-election on 19.11.1994, " +
      "vice the hon. as peacock (resigned). re-elected 1996, 1998, 2001, 2004 and 2007.")
    assert_equal("1994-11-19", fromdate)
    assert_equal("by_election", fromwhy)        
  end
  
  # This example has parliamentary service text for both the Senate and the House of Representative
  def test_member_in_senate_and_house_of_representatives
    fromdate, fromwhy = MemberParser.parse_parliamentary_service_text(
      "Elected to the Senate for New South Wales 1987 (term deemed to have begun 1.7.1987) " +
      "and 1990. Resigned 24.2.1994. Elected to the House of Representatives for Mackellar, " +
      "New South Wales, at by-election 26.3.94 vice the Hon. JJ Carlton (resigned). Re-elected " +
      "1996, 1998, 2001 and 2004.")
    assert_equal("1994-03-26", fromdate)
    assert_equal("by_election", fromwhy)
  end
  
  # Extract house of representatives section
  def test_extract_house_section_from_parliamentary_service
    house_section =
      "elected to the house of representatives for namadgi, " +
      "australian capital territory, 1996. re-elected following 1997 electoral redistribution for " +
      "canberra, australian capital territory, 1998, 2001, 2004 and 2007."
    parliamentary_service1 = 
        "australian capital territory: elected to the australian capital territory legislative assembly " +
        "15.2.1992. defeated 18.2.1995. federal: " + house_section
    parliamentary_service2 = parliamentary_service1 + " Elected to the Senate for blah blah blah."
    assert_equal(house_section,
      MemberParser.extract_house_section_from_parliamentary_service(parliamentary_service1))
    assert_equal(house_section,
      MemberParser.extract_house_section_from_parliamentary_service(parliamentary_service2))
  end
  
  # Elected at general election
  def test_elected_at_general_election
    fromdate, fromwhy = MemberParser.parse_parliamentary_service_text(
      "australian capital territory: elected to the australian capital territory legislative assembly " +
      "15.2.1992. defeated 18.2.1995. federal: elected to the house of representatives for namadgi, " +
      "australian capital territory, 1996. re-elected following 1997 electoral redistribution for " +
      "canberra, australian capital territory, 1998, 2001, 2004 and 2007.")
    assert_equal("1996-03-02", fromdate)
    assert_equal("general_election", fromwhy)        
  end
  
  # General election 1993, defeated 1996, general election 1996
  # Non contiguous service.
  def test_non_contiguous_service
    fromdate, fromwhy = MemberParser.parse_parliamentary_service_text(
      "Elected to the House of Representatives for Lilley, Queensland, 1993. Defeated at general " +
      "elections 1996. Re-elected 1998, 2001 and 2004.")
      assert_equal("1998-10-03", fromdate)
      assert_equal("general_election", fromwhy)
  end
  
  # Helper
  
  def read_member(filename)
    doc = Hpricot(open(File.join(@source, filename)))
    MemberParser::parse(@url, doc)
  end
end

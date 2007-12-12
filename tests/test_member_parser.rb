#!/usr/bin/env ruby

require 'member-parser'
require 'test/unit'

class TestMemberParser < Test::Unit::TestCase
    # mp-13329.html
    # mp-13291.html
    # mp-11881.html
    # mp-11838.html
    # mp-12065.html
    # 
        
    def test_from_date_simple
        doc = Hpricot(open("tests/source/Kate_Ellis.html"))
        member = MemberParser::parse(doc)
        
        assert_equal("2004-10-07", member.fromdate)
        assert_equal("general_election", member.fromwhy)        
    end
    
    def test_from_date_by_election
        doc = Hpricot(open("tests/source/mp-13291.html"))
        member = MemberParser::parse(doc)
        
        assert_equal("1986-02-08", member.fromdate)
        assert_equal("by_election", member.fromwhy)
        
        # Looks like a normal mp not sure 
        # why I selected it for tests
        doc = Hpricot(open("tests/source/mp-11838.html"))
        member = MemberParser::parse(doc)
        
        assert_equal("2001-07-14", member.fromdate)
        assert_equal("by_election", member.fromwhy)
    end
    
    def test_from_date_multi_line
        # multiple lines state and fed only interested in fed
        doc = Hpricot(open("tests/source/mp-12065.html"))
        member = MemberParser::parse(doc)
        
        assert_equal("1994-03-26", member.fromdate)
        assert_equal("by_election", member.fromwhy)
        
        # multiple lines, 2nd line relected dates
        # contiguous service.
        doc = Hpricot(open("tests/source/mp-13291.html"))
        member = MemberParser::parse(doc)
        
        assert_equal("1986-02-08", member.fromdate)
        assert_equal("by_election", member.fromwhy)
    end
    
    def test_from_date_non_contiguous
        # generl election 1993, defeated 1996, general election 1996
        # non contiguous service.
        doc = Hpricot(open("tests/source/mp-11881.html"))
        member = MemberParser::parse(doc)
        
        assert_equal("1998-10-03", member.fromdate)
        assert_equal("general_election", member.fromwhy)
    end
    
end

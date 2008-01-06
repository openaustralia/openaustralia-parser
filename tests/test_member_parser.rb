#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/.."

require 'member-parser'
require 'test/unit'

class TestMemberParser < Test::Unit::TestCase
    def setup
      @url = URI.parse("http://foo.co.uk")
      @source = File.join(File.dirname(__FILE__), "source")
    end
    
    def test_petro_georgiou
      member = read_member("Petro_Georgiou.html")

      assert_equal("1994-11-19", member.fromdate)
      assert_equal("by_election", member.fromwhy)        
    end
    
    def test_annette_ellis
      member = read_member("Annette_Ellis.html")
      
      assert_equal("1996-03-02", member.fromdate)
      assert_equal("general_election", member.fromwhy)        
    end
    
    def test_from_date_simple
        member = read_member("Kate_Ellis.html")
        
        assert_equal("2004-10-07", member.fromdate)
        assert_equal("general_election", member.fromwhy)        
    end
    
    def test_from_date_by_election
        member = read_member("mp-13291.html")
        
        assert_equal("1986-02-08", member.fromdate)
        assert_equal("by_election", member.fromwhy)
        
        # Looks like a normal mp not sure 
        # why I selected it for tests
        member = read_member("mp-11838.html")
        
        assert_equal("2001-07-14", member.fromdate)
        assert_equal("by_election", member.fromwhy)
    end
    
    def test_from_date_multi_line
        # multiple lines state and fed only interested in fed
        member = read_member("mp-12065.html")
        
        assert_equal("1994-03-26", member.fromdate)
        assert_equal("by_election", member.fromwhy)
        
        # multiple lines, 2nd line relected dates
        # contiguous service.
        member = read_member("mp-13291.html")
        
        assert_equal("1986-02-08", member.fromdate)
        assert_equal("by_election", member.fromwhy)
    end
    
    def test_from_date_non_contiguous
        # generl election 1993, defeated 1996, general election 1996
        # non contiguous service.
        member = read_member("mp-11881.html")
        
        assert_equal("1998-10-03", member.fromdate)
        assert_equal("general_election", member.fromwhy)
    end
    
    # Helper
    
    def read_member(filename)
      doc = Hpricot(open(File.join(@source, filename)))
      MemberParser::parse(@url, doc)
    end
end

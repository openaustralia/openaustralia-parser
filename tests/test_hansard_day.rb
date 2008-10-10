$:.unshift "#{File.dirname(__FILE__)}/../lib"

require "test/unit"

require "hansard_day"
require 'rubygems'
require 'hpricot'
require 'house'

class TestHansardDay < Test::Unit::TestCase
  def setup
    @header = HansardDay.new(Hpricot.XML('
    <hansard xsi:noNamespaceSchemaLocation="../../hansard.xsd" version="2.1">
      <session.header>
        <date>2008-09-25</date>
        <parliament.no>42</parliament.no>
        <session.no>1</session.no>
        <period.no>3</period.no>
        <chamber>SENATE</chamber>
        <page.no>0</page.no>
        <proof>1</proof>
      </session.header>
    </hansard>'))
  end
  
  def test_house
    assert_equal(House.senate, @header.house)
  end
  
  def test_date
    assert_equal(Date.new(2008, 9, 25), @header.date)
  end
  
  def test_permanent_url
    # Make permanent url links back to the Parlinfo Search result. For the time being we will always link back to the top level
    # result for that date rather than the individual speeches.
    assert_equal("http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:chamber/hansards/2008-09-25/0000", @header.permanent_url)
  end
end
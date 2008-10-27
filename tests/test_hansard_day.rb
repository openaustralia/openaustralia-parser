#!/usr/bin/env ruby

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
    
    @titles = HansardDay.new(Hpricot.XML('
    <hansard>
      <chamber.xscript>
        <debate>
       		<debateinfo><title>1</title></debateinfo>
       		<speech></speech>
        </debate>

        <debate>
          <debateinfo><title>2</title></debateinfo>
          <subdebate.1>
            <subdebateinfo><title>3</title><title>14</title></subdebateinfo>
         		<speech></speech>
          </subdebate.1>
        </debate>

        <debate>
          <debateinfo><title>4</title></debateinfo>
          <subdebate.1>
            <subdebateinfo><title>5</title></subdebateinfo>
         		<speech></speech>
          </subdebate.1>
          <subdebate.1>
            <subdebateinfo><title>6</title></subdebateinfo>
         		<speech></speech>
          </subdebate.1>
        </debate>

        <debate>
          <debateinfo>
            <title>7</title>
            <cognate>
              <cognateinfo><title>13</title></cognateinfo>
            </cognate>
          </debateinfo>
          <subdebate.1>
            <subdebateinfo><title>8</title></subdebateinfo>
         		<speech></speech>
          </subdebate.1>
          <subdebate.1>
            <subdebateinfo><title>9</title></subdebateinfo>
         		<speech></speech>
          </subdebate.1>
        </debate>
        
        <debate>
    			<debateinfo><title>10</title></debateinfo>
    			<subdebate.1>
    				<subdebateinfo><title>11</title></subdebateinfo>
    				<subdebate.2>
    					<subdebateinfo><title>12</title></subdebateinfo>
           		<speech></speech>
    				</subdebate.2>
    			</subdebate.1>
    		</debate>
      </chamber.xscript>
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
  
  def test_titles
    assert_equal([nil, ["1", ""], ["2", "3; 14"], ["4", "5"], ["4", "6"], ["7; 13", "8"], ["7; 13", "9"], ["10", "11; 12"]],
      @titles.pages.map {|page| [page.hansard_title, page.hansard_subtitle] if page})
  end
end
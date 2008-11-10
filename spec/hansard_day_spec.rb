$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'rubygems'
require 'test/unit'
require 'spec'

require 'hansard_day'

describe HansardDay do
  before(:each) do
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

  it "should know what house it's in" do
    @header.house.should == House.senate
  end

  it "should know the date" do
    @header.date.should == Date.new(2008, 9, 25)
  end

  it "should know the permanent url" do
    # Make permanent url links back to the Parlinfo Search result. For the time being we will always link back to the top level
    # result for that date rather than the individual speeches.
    @header.permanent_url.should == "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:chamber/hansards/2008-09-25/0000"
  end
  
  # TODO: This should be a test for HansardPage rather than HansardDay
  it "should be able to figure out all the titles" do
     @titles.pages.map {|page| page.hansard_title if page}.should == [nil, "1", "2", "4", "4", "7; 13", "7; 13", "10"]
  end  

  # TODO: This should be a test for HansardPage rather than HansardDay
  it "should be able to figure out all the subtitles" do
     @titles.pages.map {|page| page.hansard_subtitle if page}.should == [nil, "", "3; 14", "5", "6", "8", "9", "11; 12"]
  end
  
  # TODO: This should be a test for HansardPage rather than HansardDay
  it "should still be able to figure out the title even when there is a title tag within a title tag" do
    titles = HansardDay.new(Hpricot.XML('
    <hansard>
      <chamber.xscript>        
        <debate>
          <debateinfo>
            <title>1</title>
            <cognate><cognateinfo><title>2</title></cognateinfo></cognate>
            <cognate><cognateinfo><title>3</title></cognateinfo></cognate>
            <cognate><cognateinfo><title><title>4</title></title></cognateinfo></cognate>
            <cognate><cognateinfo><title><title>5</title></title></cognateinfo></cognate>
          </debateinfo>
          <subdebate.1>
            <subdebateinfo>
              <title>6</title>
            </subdebateinfo>
            <speech></speech>
          </subdebate.1>
        </debate>
      </chamber.xscript>        
    </hansard>'))
    
    titles.pages[1].hansard_title.should == "1; 2; 3; 4; 5"
    titles.pages[1].hansard_subtitle.should == "6"
  end
end
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
  end

  it "should know what house it's in" do
    @header.house.should == House.senate
  end
end
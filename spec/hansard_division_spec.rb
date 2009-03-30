$:.unshift "#{File.dirname(__FILE__)}/../lib"

require "test/unit"
require 'spec'

require "hansard_division"
require 'hpricot'

describe HansardDivision do
  it "should parse the xml for a division correctly" do
    division = HansardDivision.new(Hpricot.XML('
    <division>
			<division.header>
				<time.stamp>09:06:00</time.stamp>
				<para>The House divided.&#xA0;&#xA0;&#xA0;&#xA0; </para>
			</division.header>
			<para>(The Speaker&#x2014;Mr Harry Jenkins)</para>
			<division.data>
				<ayes>
					<num.votes>2</num.votes>
					<title>AYES</title>
					<names>
						<name>Joe Bloggs</name>
						<name>Henry Smith</name>
					</names>
				</ayes>
				<noes>
					<num.votes>1</num.votes>
					<title>NOES</title>
					<names>
						<name>John Smith</name>
					</names>
				</noes>
			</division.data>
			<para>* denotes teller</para>
			<division.result>
				<para>Question agreed to.</para>
			</division.result>
		</division>'))
		division.yes.should == ["Joe Bloggs", "Henry Smith"]
		division.no.should == ["John Smith"]
		division.time.should == "09:06:00"
  end
end

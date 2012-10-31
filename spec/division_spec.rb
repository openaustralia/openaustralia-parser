$:.unshift "#{File.dirname(__FILE__)}/../lib"

require "test/unit"

require "division"
require 'house'
require 'person'
require 'name'
require 'builder_alpha_attributes'
require 'count'

# The Division class knows how to output XML
describe Division do
  before :each do
    john_person = Person.new(:name => Name.new(:first => "John", :last => "Smith"), :count => 1)
    joe_person = Person.new(:name => Name.new(:first => "Joe", :last => "Smith"), :count => 2)
    henry_person = Person.new(:name => Name.new(:first => "Henry", :last => "Smith"), :count => 3)
    jack_person = Person.new(:name => Name.new(:first => "Jack", :last => "Smith"), :count => 4)

    john_member = Period.new(:person => john_person, :house => House.representatives, :count => 1)
    joe_member = Period.new(:person => joe_person, :house => House.representatives, :count => 2)
    henry_member = Period.new(:person => henry_person, :house => House.representatives, :count => 3)

    # John and Joe vote yes and Henry votes no. John and Henry are tellers
    @division1 = Division.new([john_member, joe_member], [henry_member], [john_member], [henry_member],
      [], "10:11:00", "http://foo/link", Count.new(10, 2), 15, Date.new(2008, 2, 1), House.representatives)

    john_member2 = Period.new(:person => john_person, :house => House.senate, :count => 1)
    joe_member2 = Period.new(:person => joe_person, :house => House.senate, :count => 2)
    henry_member2 = Period.new(:person => henry_person, :house => House.senate, :count => 3)
    jack_member2 = Period.new(:person => jack_person, :house => House.senate, :count => 4)
    
    @division2 = Division.new([john_member2], [], [], [], [], "9:10:00", "http://foo/link", Count.new(1, 2), 3, Date.new(2008, 2, 1), House.senate)

    @division3 = Division.new([], [], [], [], [[john_member2, joe_member2], [henry_member2, jack_member2]],
      "9:10:00", "http://foo/link", Count.new(1, 2), 3, Date.new(2008, 2, 1), House.senate)
  end
  
  it "has the id in the correct form" do
    # Time, URL, Major count, Minor count, Date, and house
    @division1.id.should == "uk.org.publicwhip/debate/2008-02-01.10.2"
  end
  
  it "can output xml in the expected form" do
    # Default builder will return value as string
    x = Builder::XmlMarkup.new(:indent => 2)
    @division1.output(x).should == <<EOF
<division divdate="2008-02-01" divnumber="15" id="uk.org.publicwhip/debate/2008-02-01.10.2" nospeaker="true" time="10:11:00" url="http://foo/link">
  <divisioncount ayes="2" noes="1" tellerayes="1" tellernoes="1"/>
  <memberlist vote="aye">
    <member id="uk.org.publicwhip/member/1" teller="yes" vote="aye">John Smith</member>
    <member id="uk.org.publicwhip/member/2" vote="aye">Joe Smith</member>
  </memberlist>
  <memberlist vote="no">
    <member id="uk.org.publicwhip/member/3" teller="yes" vote="no">Henry Smith</member>
  </memberlist>
</division>
EOF
  end
  
  it "can output the slightly different form of the xml for the senate" do
    x = Builder::XmlMarkup.new(:indent => 2)
    @division2.output(x).should == <<EOF
<division divdate="2008-02-01" divnumber="3" id="uk.org.publicwhip/lords/2008-02-01.1.2" nospeaker="true" time="9:10:00" url="http://foo/link">
  <divisioncount ayes="1" noes="0" tellerayes="0" tellernoes="0"/>
  <memberlist vote="aye">
    <member id="uk.org.publicwhip/lord/100001" vote="aye">John Smith</member>
  </memberlist>
  <memberlist vote="no">
  </memberlist>
</division>
EOF
  end
  
  it "should output voting pairs" do
    x = Builder::XmlMarkup.new(:indent => 2)
    @division3.output(x).should == <<EOF
<division divdate="2008-02-01" divnumber="3" id="uk.org.publicwhip/lords/2008-02-01.1.2" nospeaker="true" time="9:10:00" url="http://foo/link">
  <divisioncount ayes="0" noes="0" pairs="2" tellerayes="0" tellernoes="0"/>
  <memberlist vote="aye">
  </memberlist>
  <memberlist vote="no">
  </memberlist>
  <pairs>
    <pair>
      <member id="uk.org.publicwhip/lord/100001">John Smith</member>
      <member id="uk.org.publicwhip/lord/100002">Joe Smith</member>
    </pair>
    <pair>
      <member id="uk.org.publicwhip/lord/100003">Henry Smith</member>
      <member id="uk.org.publicwhip/lord/100004">Jack Smith</member>
    </pair>
  </pairs>
</division>
EOF
  end
end
  

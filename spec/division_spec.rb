# frozen_string_literal: true

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../lib"

require "test/unit"

require "division"
require "house"
require "person"
require "name"
require "builder_alpha_attributes"
require "count"

# The Division class knows how to output XML
describe Division do
  before :each do
    john_person = Person.new(name: Name.new(first: "John", last: "Smith"), count: 1)
    joe_person = Person.new(name: Name.new(first: "Joe", last: "Smith"), count: 2)
    henry_person = Person.new(name: Name.new(first: "Henry", last: "Smith"), count: 3)
    jack_person = Person.new(name: Name.new(first: "Jack", last: "Smith"), count: 4)

    john_member = Period.new(person: john_person, house: House.representatives, count: 1)
    joe_member = Period.new(person: joe_person, house: House.representatives, count: 2)
    henry_member = Period.new(person: henry_person, house: House.representatives, count: 3)

    # John and Joe vote yes and Henry votes no. John and Henry are tellers
    @division1 = Division.new(yes_members: [john_member, joe_member], no_members: [henry_member], yes_tellers: [john_member], no_tellers: [henry_member],
                              pairs: [], time: "10:11:00", url: "http://foo/link", bills: [{ id: "Z12345", title: "A bill to support mongeese", url: "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:legislation/billhome/Z12345" }], count: Count.new(10, 2), division_count: 15, date: Date.new(2008, 2, 1), house: House.representatives)

    john_member2 = Period.new(person: john_person, house: House.senate, count: 1)
    joe_member2 = Period.new(person: joe_person, house: House.senate, count: 2)
    henry_member2 = Period.new(person: henry_person, house: House.senate, count: 3)
    jack_member2 = Period.new(person: jack_person, house: House.senate, count: 4)

    @division2 = Division.new(yes_members: [john_member2], no_members: [], yes_tellers: [], no_tellers: [], pairs: [],
                              time: "9:10:00", url: "http://foo/link", bills: [{ id: "Z12345", title: "A bill to support mongeese", url: "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:legislation/billhome/Z12345" }], count: Count.new(1, 2), division_count: 3, date: Date.new(2008, 2, 1), house: House.senate)

    @division3 = Division.new(yes_members: [], no_members: [], yes_tellers: [], no_tellers: [], pairs: [[john_member2, joe_member2], [henry_member2, jack_member2]],
                              time: "9:10:00", url: "http://foo/link", bills: [{ id: "Z12345", title: "A bill to support mongeese", url: "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:legislation/billhome/Z12345" }], count: Count.new(1, 2), division_count: 3, date: Date.new(2008, 2, 1), house: House.senate)
  end

  it "has the id in the correct form" do
    # Time, URL, Major count, Minor count, Date, and house
    expect(@division1.id).to eq "uk.org.publicwhip/debate/2008-02-01.10.2"
  end

  it "can output xml in the expected form" do
    # Default builder will return value as string
    x = Builder::XmlMarkup.new(indent: 2)
    expect(@division1.output(x)).to eq <<~XML
      <division divdate="2008-02-01" divnumber="15" id="uk.org.publicwhip/debate/2008-02-01.10.2" nospeaker="true" time="10:11:00" url="http://foo/link">
        <bills>
          <bill id="Z12345" url="http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:legislation/billhome/Z12345">A bill to support mongeese</bill>
        </bills>
        <divisioncount ayes="2" noes="1" tellerayes="1" tellernoes="1"/>
        <memberlist vote="aye">
          <member id="uk.org.publicwhip/member/1" teller="yes" vote="aye">John Smith</member>
          <member id="uk.org.publicwhip/member/2" vote="aye">Joe Smith</member>
        </memberlist>
        <memberlist vote="no">
          <member id="uk.org.publicwhip/member/3" teller="yes" vote="no">Henry Smith</member>
        </memberlist>
      </division>
    XML
  end

  it "can output the slightly different form of the xml for the senate" do
    x = Builder::XmlMarkup.new(indent: 2)
    expect(@division2.output(x)).to eq <<~XML
      <division divdate="2008-02-01" divnumber="3" id="uk.org.publicwhip/lords/2008-02-01.1.2" nospeaker="true" time="9:10:00" url="http://foo/link">
        <bills>
          <bill id="Z12345" url="http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:legislation/billhome/Z12345">A bill to support mongeese</bill>
        </bills>
        <divisioncount ayes="1" noes="0" tellerayes="0" tellernoes="0"/>
        <memberlist vote="aye">
          <member id="uk.org.publicwhip/lord/100001" vote="aye">John Smith</member>
        </memberlist>
        <memberlist vote="no">
        </memberlist>
      </division>
    XML
  end

  it "should output voting pairs" do
    x = Builder::XmlMarkup.new(indent: 2)
    expect(@division3.output(x)).to eq <<~XML
      <division divdate="2008-02-01" divnumber="3" id="uk.org.publicwhip/lords/2008-02-01.1.2" nospeaker="true" time="9:10:00" url="http://foo/link">
        <bills>
          <bill id="Z12345" url="http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:legislation/billhome/Z12345">A bill to support mongeese</bill>
        </bills>
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
    XML
  end
end

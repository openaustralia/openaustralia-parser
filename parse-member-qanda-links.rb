#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'mechanize_proxy'
require 'name'
require 'people'
require 'configuration'

conf = Configuration.new

agent = MechanizeProxy.new
agent.cache_subdirectory = "parse-member-qanda-links"

# First get mapping between constituency name and web page
page = agent.get('http://www.abc.net.au/tv/qanda/find-your-local-mp-by-electorate.htm')

map = {}
page.links[35..183].each do |link|
  map[link.text.downcase] = page.uri + link.uri
end
map["flynn"] = "http://www.abc.net.au/tv/qanda/mp-profiles/flyn.htm"

puts "Reading member data..."
people = People.read_csv("data/members.csv", "data/ministers.csv", "data/shadow-ministers.csv")

members = people.find_current_house_members

xml = File.open("#{conf.members_xml_path}/links-abc-qanda.xml", 'w')
x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
x.instruct!
x.publicwhip do
  members.each do |member|
    short_division = member.division.downcase[0..3]
    link = map[member.division.downcase]
    throw "Couldn't lookup division #{member.division}" if link.nil?
    x.personinfo(:id => member.person.id, :mp_biography_qanda => link)
  end
end
xml.close

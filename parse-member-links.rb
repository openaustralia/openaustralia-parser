#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'mechanize_proxy'
require 'name'
require 'people'
require 'configuration'

conf = Configuration.new

agent = MechanizeProxy.new
agent.cache_subdirectory = "parse-member-links"

puts "Reading member data..."
people = People.read_csv("data/members.csv", "data/ministers.csv", "data/shadow-ministers.csv")

puts "Downloading information..."
data = []

page = agent.get('http://www.aph.gov.au/house/members/mi-alpha.asp')
page.links[19..-4].each do |link|
  name = Name.last_title_first(link.text.split(',')[0..1].join(','))
  sub_page = agent.click(link)
  home_page_tag = sub_page.links.find{|l| l.text == "Personal Home Page"}
  if home_page_tag
    uri = home_page_tag.uri
    puts "Name: #{name.full_name}, URL: #{uri}"
    item = OpenStruct.new
    person = people.find_person_by_name_current_on_date(name, Date.today)
    if person
      item.person_id = person.id
      item.uri = uri
      data << item
    else
      puts "WARNING: Could not find person with name #{name.full_name}"
    end
  end
end

xml = File.open("#{conf.members_xml_path}/websites.xml", 'w')
x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
x.instruct!
x.publicwhip do
  data.each do |item|
    x.personinfo(:id => item.person_id, :mp_website => item.uri)
  end
end
xml.close

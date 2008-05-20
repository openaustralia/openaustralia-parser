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
  person = people.find_person_by_name_current_on_date(name, Date.today)
  if person
    item = OpenStruct.new
    item.person_id = person.id
    sub_page = agent.click(link)
    item.mp_contactdetails = sub_page.uri
    home_page_tag = sub_page.links.find{|l| l.text == "Personal Home Page"}
    item.uri = home_page_tag.uri if home_page_tag
    data << item
  else
    puts "WARNING: Could not find person with name #{name.full_name}"
  end

end

xml = File.open("#{conf.members_xml_path}/websites.xml", 'w')
x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
x.instruct!
x.publicwhip do
  data.each do |item|
    params = {:id => item.person_id}
    params[:mp_website] = item.uri if item.uri
    params[:mp_contactdetails] = item.mp_contactdetails if item.mp_contactdetails
    x.personinfo(params)
  end
end
xml.close

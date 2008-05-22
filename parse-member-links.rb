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

page = agent.get('http://www.aph.gov.au/house/members/mi-alpha.asp')

xml = File.open("#{conf.members_xml_path}/websites.xml", 'w')
x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
x.instruct!

x.publicwhip do
  page.links[19..-4].each do |link|
    name = Name.last_title_first(link.text.split(',')[0..1].join(','))
    person = people.find_person_by_name_current_on_date(name, Date.today)
    if person
      sub_page = agent.click(link)
      home_page_tag = sub_page.links.find{|l| l.text == "Personal Home Page"}
      
      params = {:id => person.id, :mp_contactdetails => sub_page.uri}
      params[:mp_website] = home_page_tag.uri if home_page_tag
      x.personinfo(params)

    else
      puts "WARNING: Could not find person with name #{name.full_name}"
    end
  end
end

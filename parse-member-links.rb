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
people = PeopleCSVReader.read_members

puts "Personal home page & Contact Details (Gov website)..."

def extract_links(name, people, agent, link, x)
  person = people.find_person_by_name_current_on_date(name, Date.today)
  if person
    sub_page = agent.click(link)
    home_page_tag = sub_page.links.find{|l| l.text =~ /personal home page/i}
    
    params = {:id => person.id, :mp_contactdetails => sub_page.uri}
    params[:mp_website] = home_page_tag.uri if home_page_tag
    x.personinfo(params)
  else
    puts "WARNING: Could not find person with name #{name.full_name}"
  end
end

xml = File.open("#{conf.members_xml_path}/websites.xml", 'w')
x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
x.instruct!
x.publicwhip do
  if conf.write_xml_representatives
    agent.get(conf.alternative_current_house_members_url).links.each do |link|
      if link.to_s =~ /Member for/
        name = Name.last_title_first(link.text.split(',')[0..1].join(','))
        extract_links(name, people, agent, link, x)
      end
    end
  end
  if conf.write_xml_senators
    agent.get(conf.alternative_current_senate_members_url).links.each do |link|
      if link.to_s =~ /Senator/
        name = Name.last_title_first(link.to_s.split('-')[0..-2].join('-'))
        extract_links(name, people, agent, link, x)
      end
    end
  end
end
xml.close

if conf.write_xml_representatives
  puts "Q&A Links..."

  # First get mapping between constituency name and web page
  page = agent.get(conf.qanda_electorate_url)
  map = {}

  page.links[35..184].each do |link|
    map[link.text.downcase] = (page.uri + link.uri).to_s
  end
  # Hack to deal with "Flynn" constituency incorrectly spelled as "Flyn"
  map["flynn"] = "http://www.abc.net.au/tv/qanda/mp-profiles/flyn.htm"

  bad_divisions = []
  # Check that the links point to valid pages
  map.each_pair do |division, url|
    begin
      agent.get(url)
    rescue WWW::Mechanize::ResponseCodeError
      bad_divisions << division
      puts "ERROR: Invalid url #{url} for division #{division}"
    end
  end
  # Clear out bad divisions
  bad_divisions.each { |division| map.delete(division) }

  xml = File.open("#{conf.members_xml_path}/links-abc-qanda.xml", 'w')
  x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
  x.instruct!
  x.publicwhip do
    people.find_current_members(House.representatives).each do |member|
      short_division = member.division.downcase[0..3]
      link = map[member.division.downcase]
      puts "ERROR: Couldn't lookup division #{member.division}" if link.nil?
      x.personinfo(:id => member.person.id, :mp_biography_qanda => link)
    end
  end
  xml.close
end

system(conf.web_root + "/twfy/scripts/mpinfoin.pl links")

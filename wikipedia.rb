#!/usr/bin/env ruby
# Figures out the URLs for the Wikipedia biography pages of Representatives and Senators

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'name'
require 'people'
require 'mechanize_proxy'
require 'configuration'
require 'extract_wikipedia_links'

def write_links(links, filename)
  xml = File.open(filename, 'w')
  x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
  x.instruct!  
  x.peopleinfo do
    links.each { |link| x.personinfo(:id => link[0], :wikipedia_url => link[1]) }
  end
  xml.close
end

conf = Configuration.new

puts "Reading member data..."
people = people = PeopleCSVReader.read_members

agent = MechanizeProxy.new
# Slightly naughty because Wikipedia specifically blocks Ruby Mechanize but I'm justifying it because we
# are using the html_cache here so that will mean there is a very small amount of traffic generally
agent.user_agent_alias = 'Mac Safari'
agent.cache_subdirectory = "wikipedia"

if conf.write_xml_representatives
  puts "Wikipedia links for Representatives..."
  links = extract_all_representative_wikipedia_links(people, agent)
  write_links(links, "#{conf.members_xml_path}/wikipedia-commons.xml")
  # For Representatives just for curiousity sake find out which has a link back to OpenAustralia
  links.each {|link| check_wikipedia_page(link[1], agent) }
end
if conf.write_xml_senators
  puts "Wikipedia links for Senators..."
  write_links(extract_all_senator_wikipedia_links(people, agent), "#{conf.members_xml_path}/wikipedia-lords.xml")
end

system(conf.web_root + "/twfy/scripts/mpinfoin.pl links")

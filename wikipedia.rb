#!/usr/bin/env ruby
# Figures out the URLs for the Wikipedia biography pages of Representatives and Senators

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'name'
require 'people'
require 'hpricot'
require 'open-uri'
require 'configuration'

def extract_links_from_wikipedia(doc, people)
  links = {}
  doc.search("//table[@class='wikitable sortable']").search("tr").each do |row|
    link = row.search('td a')[0]
    if link
      name = Name.title_first_last(link.inner_html)
      person = people.find_person_by_name(name)
      if person
        links[person.id] = "http://en.wikipedia.org#{link.get_attribute("href")}"
      else
        puts "WARNING: Could not find person with name #{name.full_name}" 
      end 
    end
  end
  links
end

def write_links(links, filename)
  xml = File.open(filename, 'w')
  x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
  x.instruct!  
  x.publicwhip do
    links.each { |link| x.personinfo(:id => link[0], :wikipedia_url => link[1]) }
  end
  xml.close
end

conf = Configuration.new

puts "Reading member data..."
people = people = PeopleCSVReader.read_members

if conf.write_xml_representatives
  puts "Wikipedia links for Representatives..."
  links = extract_links_from_wikipedia(
    Hpricot(open("http://en.wikipedia.org/wiki/Members_of_the_Australian_House_of_Representatives%2C_2007-2010")), people)
  write_links(links, "#{conf.members_xml_path}/wikipedia-commons.xml")
end
if conf.write_xml_senators
  puts "Wikipedia links for Senators..."
  links = extract_links_from_wikipedia(
    Hpricot(open("http://en.wikipedia.org/wiki/Members_of_the_Australian_Senate%2C_2005-2008")), people)
  write_links(links, "#{conf.members_xml_path}/wikipedia-lords.xml")
end

system(conf.web_root + "/twfy/scripts/mpinfoin.pl links")

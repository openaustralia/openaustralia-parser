#!/usr/bin/env ruby
# Figures out the URLs for the Wikipedia biography pages of Representatives and Senators

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'name'
require 'people'
require 'hpricot'
require 'open-uri'
require 'configuration'

def extract_links_from_wikipedia(doc, people, links)
  doc.search("//table").first.search("tr").each do |row|
    link = row.search('td a')[0]
    if link
      name = Name.title_first_last(link.inner_html)
      person = people.find_person_by_name(name)
      if person
        url = "http://en.wikipedia.org#{link.get_attribute("href")}"
        if links.has_key?(person.id) && links[person.id] != url
          puts "WARNING: URL for #{name.full_name} has multiple different values"
        else
          links[person.id] = url
        end
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
  links = {}
  #["1980", "1983", "1984", "1987", "1990", "1993", "1996", "1998", "2001", "2004", "2007", "2010"].each_cons(2) do |pair|
  # Only going to get wikipedia links going back to 2004 for the time being
  ["2004", "2007", "2010"].each_cons(2) do |pair|
    puts "Analysing years #{pair[0]}-#{pair[1]}"
    extract_links_from_wikipedia(
      Hpricot(open("http://en.wikipedia.org/wiki/Members_of_the_Australian_House_of_Representatives%2C_#{pair[0]}-#{pair[1]}")),
      people, links)
  end
  write_links(links, "#{conf.members_xml_path}/wikipedia-commons.xml")
end
if conf.write_xml_senators
  puts "Wikipedia links for Senators..."
  links = {}
  extract_links_from_wikipedia(
    Hpricot(open("http://en.wikipedia.org/wiki/Members_of_the_Australian_Senate%2C_2005-2008")), people, links)
  write_links(links, "#{conf.members_xml_path}/wikipedia-lords.xml")
end

system(conf.web_root + "/twfy/scripts/mpinfoin.pl links")

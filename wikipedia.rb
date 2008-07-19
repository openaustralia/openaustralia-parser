#!/usr/bin/env ruby
# Figures out the URLs for the Wikipedia biography pages of Representatives and Senators

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'name'
require 'people'
require 'hpricot'
require 'open-uri'
require 'configuration'

def extract_links_from_wikipedia(doc, filename, people)
  xml = File.open(filename, 'w')
  x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
  x.instruct!  
  x.publicwhip do
    doc.search("//table[@class='wikitable sortable']").search("tr").each do |row|
      link = row.search('td a')[0]
      if link
        name = Name.title_first_last(link.inner_html)
        person = people.find_person_by_name_current_on_date(name, Date.today)
        if person
          x.personinfo(:id => person.id, :wikipedia_url => "http://en.wikipedia.org#{link.get_attribute("href")}")
        else
          puts "WARNING: Could not find person with name #{name.full_name}" 
        end 
      end
    end
  end
  xml.close
end

conf = Configuration.new

puts "Reading member data..."
people = people = PeopleCSVReader.read_members

puts "Wikipedia links for Representatives..."
extract_links_from_wikipedia(
  Hpricot(open("http://en.wikipedia.org/wiki/Members_of_the_Australian_House_of_Representatives%2C_2007-2010")),
  "#{conf.members_xml_path}/wikipedia-commons.xml", people) if conf.write_xml_representatives
puts "Wikipedia links for Senators..."
extract_links_from_wikipedia(
  Hpricot(open("http://en.wikipedia.org/wiki/Members_of_the_Australian_Senate%2C_2005-2008")),
  "#{conf.members_xml_path}/wikipedia-lords.xml", people) if conf.write_xml_senators

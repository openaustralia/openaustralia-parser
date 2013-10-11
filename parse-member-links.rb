#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'environment'
require 'mechanize'
require 'open-uri'
require 'name'
require 'people'
require 'hpricot'
require 'configuration'
require 'json'

conf = Configuration.new

# Not using caching proxy since we will be running this script once a day and we
# always want to get the new data
agent = WWW::Mechanize.new

puts "Reading member data..."
people = PeopleCSVReader.read_members

puts "Personal home page & Contact Details (Gov website)..."

xml = File.open("#{conf.members_xml_path}/websites.xml", 'w')
x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
x.instruct!
x.peopleinfo do
  scraperwiki_result = agent.get('https://api.scraperwiki.com/api/1.0/datastore/sqlite?format=jsondict&name=australian_federal_parliament_senators_members_off&query=select%20*%20from%20%60swdata%60').body
  JSON.parse(scraperwiki_result).each do |person|
    p = people.find_person_by_aph_id(person['aph_id'].upcase)
    params = {:id => p.id, :mp_contactdetails => person['contact_page']}
    params[:mp_website] = person['website'] if person['website']
    x.personinfo(params)
  end
end
xml.close

abc_root = "http://www.abc.net.au"
xml = File.open("#{conf.members_xml_path}/links-abc-election.xml", 'w')
x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
x.instruct!

x.consinfos do
  puts "Election results 2007 (from the abc.net.au) ..."

  # Representatives
  url = "#{conf.election_web_root}/results/electorateindex.htm"
  doc = Hpricot(open(url))
  (doc/"td.electorate").each do |td|
    href = td.at("a")['href']
    href = "#{abc_root}#{href}"
    name = td.at("a").inner_text
    name = name.gsub(/\*/,'').strip
    x.consinfo(:canonical => name, :abc_election_results_2007 => href)
  end
  # Senate
  url = "#{conf.election_web_root}/results/senate/"
  doc = Hpricot(open(url))
  (doc/:a).each do |a|
    if /results\/senate\/(\w+)\.htm/.match(a['href'])
      href = abc_root + a['href']
      name = a.inner_text
      x.consinfo(:canonical => name, :abc_election_results_2007 => href)
    end
  end

  puts "Election results 2010 (from the abc.net.au) ..."
  # Representatives
  abc_2010_root = "http://www.abc.net.au/elections/federal/2010/guide"
  url = "#{abc_2010_root}/electorateresults.htm"
  doc = Hpricot(open(url))
  (doc/"td.electorate").each do |td|
    href = td.at("a")['href']
    href = "#{abc_2010_root}/#{href}"
    name = td.at("a").inner_text
    name = name.gsub(/\*/,'').strip
    x.consinfo(:canonical => name, :abc_election_results_2010 => href)
  end
  # Senate
  [["nsw", "NSW"], ["vic", "Victoria"], ["qld", "Queensland"], ["wa", "WA"], ["sa", "SA"], ["tas", "Tasmania"], ["act", "ACT"], ["nt", "NT"]].each do |name, canonical|
    href = "http://www.abc.net.au/elections/federal/2010/guide/s#{name}-results.htm"
    x.consinfo(:canonical => canonical, :abc_election_results_2010 => href)
  end
end
xml.close

puts "Q&A Links..."

data = {}

# First get mapping between constituency name and web page
page = agent.get(conf.qanda_electorate_url)
map = {}

page.links[260..409].each do |link|
  map[link.text.downcase] = (page.uri + link.uri).to_s
end
# Hack to deal with "Durack" constituency incorrectly spelled as "Durak"
map["durack"] = map["durak"]

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

people.find_current_members(House.representatives).each do |member|
  short_division = member.division.downcase[0..3]
  link = map[member.division.downcase]
  data[member.person.id] = link
  puts "ERROR: Couldn't lookup division #{member.division}" if link.nil?
end

page = agent.get(conf.qanda_all_senators_url)
page.links.each do |link|
  if link.uri.to_s =~ /^\/tv\/qanda\/senators\//
    # HACK to handle Unicode in Kerry O'Brien's name on Q&A site
    if link.to_s == "Kerry O\222Brien"
      name_text = "Kerry O'Brien"
    else
      name_text = link.to_s
    end
    member = people.find_member_by_name_current_on_date(Name.title_first_last(name_text), Date.today, House.senate)
    if member.nil?
      puts "WARNING: Can't find Senator #{link}"
    else
      data[member.person.id] = page.uri + link.uri
    end
  end
end

xml = File.open("#{conf.members_xml_path}/links-abc-qanda.xml", 'w')
x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
x.instruct!
x.peopleinfo do
  data.each do |id, link|
    x.personinfo(:id => id, :mp_biography_qanda => link)
  end
end
xml.close

system(conf.web_root + "/twfy/scripts/mpinfoin.pl links")

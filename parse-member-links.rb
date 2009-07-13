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

puts "Twitter information (from tweetmp.org.au)..."

xml = File.open("#{conf.members_xml_path}/twitter.xml", 'w')
x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
x.instruct!
x.peopleinfo do
  JSON.parse(agent.get("http://tweetmp.org.au/api/mps.json").body).each do |person|
    aph_id = person["GovernmentId"].upcase
    twitter = person["TwitterScreenName"]
    # Lookup the person based on their government id
    p = people.find_person_by_aph_id(aph_id)
    # Temporary workaround until we figure out what's going on with the aph_id's that start with '00'
    if p.nil?
      p = people.find_person_by_aph_id("00" + aph_id)
      puts "WARNING: Couldn't find person with aph id: #{aph_id}" if p.nil?
    end
    if twitter
      x.personinfo(:id => p.id, :mp_twitter_screen_name => twitter)
    else
      # Give the URL for inviting this person to Twitter using tweetmp.org.au
      x.personinfo(:id => p.id, :mp_twitter_invite_tweetmp => "http://tweetmp.org.au/mps/invite/#{person["Id"]}")
    end
  end
end
xml.close

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
x.peopleinfo do
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

puts "Election results (from the abc.net.au) ..."

abc_root = "http://www.abc.net.au"
xml = File.open("#{conf.members_xml_path}/links-abc-election.xml", 'w')
x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
x.instruct!

x.consinfos do
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
end
xml.close

puts "Q&A Links..."

data = {}

if conf.write_xml_representatives

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

  people.find_current_members(House.representatives).each do |member|
    short_division = member.division.downcase[0..3]
    link = map[member.division.downcase]
    data[member.person.id] = link
    puts "ERROR: Couldn't lookup division #{member.division}" if link.nil?
  end
end

if conf.write_xml_senators
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

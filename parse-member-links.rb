#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"

require "mechanize"
require "open-uri"
require "name"
require "people"
require "hpricot"
require "configuration"
require "json"

conf = Configuration.new

# Not using caching proxy since we will be running this script once a day and we
# always want to get the new data
agent = Mechanize.new

puts "Reading member data..."
people = PeopleCSVReader.read_members

puts "Web pages, social media URLs and email from APH (via Morph)..."

xml = File.open("#{conf.members_xml_path}/websites.xml", "w")
x = Builder::XmlMarkup.new(target: xml, indent: 1)
x.instruct!
x.peopleinfo do
  morph_result = agent.get(
    "https://api.morph.io/openaustralia/aus_mp_contact_details/data.json", { query: 'select * from "data"' }, nil, "x-api-key" => conf.morph_api_key
  ).body
  JSON.parse(morph_result).each do |person|
    p = people.find_person_by_aph_id(person["aph_id"].upcase)
    params = { id: p.id, mp_contact_form: person["contact_page"], aph_url: person["profile_page"] }
    params[:mp_email] = person["email"] if person["email"]
    params[:mp_website] = person["website"] if person["website"]
    params[:mp_twitter_url] = person["twitter"] if person["twitter"]
    params[:mp_facebook_url] = person["facebook"] if person["facebook"]
    x.personinfo(params)
  end
end
xml.close

abc_root = "https://www.abc.net.au"
xml = File.open("#{conf.members_xml_path}/links-abc-election.xml", "w")
x = Builder::XmlMarkup.new(target: xml, indent: 1)
x.instruct!

x.consinfos do
  puts "Election results 2007 (from the abc.net.au) ..."

  # Representatives
  url = "#{conf.election_web_root}/results/electorateindex.htm"
  doc = Hpricot(URI.parse(url).open)
  (doc / "td.electorate").each do |td|
    href = td.at("a")["href"]
    href = "#{abc_root}#{href}"
    name = td.at("a").inner_text
    name = name.gsub(/\*/, "").strip
    x.consinfo("canonical" => name, "abc_election_results_2007" => href)
  end
  # Senate
  url = "#{conf.election_web_root}/results/senate/"
  doc = Hpricot(URI.parse(url).open)
  (doc / :a).each do |a|
    next unless %r{results/senate/(\w+)\.htm}.match(a["href"])

    href = abc_root + a["href"]
    name = a.inner_text
    x.consinfo("canonical" => name, "abc_election_results_2007" => href)
  end

  puts "Election results 2010 (from the abc.net.au) ..."
  # Representatives
  abc_2010_root = "https://www.abc.net.au/elections/federal/2010/guide"
  url = "#{abc_2010_root}/electorateresults.htm"
  doc = Hpricot(URI.parse(url).open)
  (doc / "td.electorate").each do |td|
    href = td.at("a")["href"]
    href = "#{abc_2010_root}/#{href}"
    name = td.at("a").inner_text
    name = name.gsub(/\*/, "").strip
    x.consinfo("canonical" => name, "abc_election_results_2010" => href)
  end
  # Senate
  [%w[nsw NSW], %w[vic Victoria], %w[qld Queensland], %w[wa WA], %w[sa SA], %w[tas Tasmania], %w[act ACT],
   %w[nt NT]].each do |name, canonical|
    href = "http://www.abc.net.au/elections/federal/2010/guide/s#{name}-results.htm"
    x.consinfo("canonical" => canonical, "abc_election_results_2010" => href)
  end

  puts "Election results 2013 (from the abc.net.au)..."
  # Representatives
  abc_root = "https://www.abc.net.au"
  url = "#{abc_root}/news/elections/federal/2013/guide/electorates"
  doc = Hpricot(URI.parse(url).open)
  (doc / "span.electorate").each do |span|
    href = span.parent["href"]
    href = "#{abc_root}#{href}"
    name = span.inner_text
    x.consinfo("canonical" => name, "abc_election_results_2013" => href)
  end
  # Senate
  [%w[nsw NSW], %w[vic Victoria], %w[qld Queensland], %w[wa WA], %w[sa SA], %w[tas Tasmania], %w[act ACT],
   %w[nt NT]].each do |name, canonical|
    href = "https://www.abc.net.au/news/federal-election-2013/results/senate/#{name}/"
    x.consinfo("canonical" => canonical, "abc_election_results_2013" => href)
  end

  puts "Election results 2016 (from the abc.net.au)..."
  # Representatives
  abc_root = "https://www.abc.net.au"
  url = "#{abc_root}/news/elections/federal/2016/guide/electorates"
  doc = agent.get(url)

  doc.search(".ert-results a").each do |a|
    href = doc.uri + a["href"]
    name = a.at("h2").inner_text.gsub(/[^a-z]/i, "")
    x.consinfo("canonical" => name, "abc_election_results_2016" => href)
  end
  # Senate
  [%w[nsw NSW], %w[vic Victoria], %w[qld Queensland], %w[wa WA], %w[sa SA], %w[tas Tasmania], %w[act ACT],
   %w[nt NT]].each do |name, canonical|
    href = "https://www.abc.net.au/news/federal-election-2016/results/senate/#s#{name}"
    x.consinfo("canonical" => canonical, "abc_election_results_2016" => href)
  end

  puts "Election results 2019 (from the abc.net.au)..."
  # Representatives
  abc_root = "https://www.abc.net.au"
  url = "#{abc_root}/news/elections/federal/2019/results/list"
  doc = agent.get(url)

  # What an absolutely ridiculous selector
  doc.search("article div div div div div div div h2").each do |h2|
    name = h2.inner_text.strip
    href = "https://www.abc.net.au/news/elections/federal/2019/guide/#{name[0..3].downcase}"
    x.consinfo("canonical" => name, "abc_election_results_2019" => href)
  end
  # Senate
  [%w[nsw NSW], %w[vic Victoria], %w[qld Queensland], %w[wa WA], %w[sa SA], %w[tas Tasmania], %w[act ACT],
   %w[nt NT]].each do |_name, canonical|
    # No seperate url for each state results... So...
    href = "https://www.abc.net.au/news/elections/federal/2019/results/senate"
    x.consinfo("canonical" => canonical, "abc_election_results_2019" => href)
  end
end
xml.close

# Commenting out Q&A links because these people's pages are not even linked
# to from the Q&A site itself now so one can only presume that they're not
# going to be kept up to date so linking to them seems like a bad idea

# puts "Q&A Links..."
#
# data = {}
#
# # First get mapping between constituency name and web page
# page = agent.get(conf.qanda_electorate_url)
# map = {}
#
# page.links[261..410].each do |link|
#   map[link.text.downcase] = (page.uri + link.uri).to_s
# end
#
# bad_divisions = []
# # Check that the links point to valid pages
# map.each_pair do |division, url|
#   begin
#     agent.get(url)
#   rescue Mechanize::ResponseCodeError
#     bad_divisions << division
#     puts "ERROR: Invalid url #{url} for division #{division}"
#   end
# end
# # Clear out bad divisions
# bad_divisions.each { |division| map.delete(division) }
#
# people.find_current_members(House.representatives).each do |member|
#   short_division = member.division.downcase[0..3]
#   link = map[member.division.downcase]
#   data[member.person.id] = link
#   puts "ERROR: Couldn't lookup division #{member.division}" if link.nil?
# end
#
# page = agent.get(conf.qanda_all_senators_url)
# page.links.each do |link|
#   if link.uri.to_s =~ /^\/tv\/qanda\/senators\//
#     # HACK to handle Unicode in Kerry O'Brien's name on Q&A site
#     if link.to_s == "Kerry O\222Brien"
#       name_text = "Kerry O'Brien"
#     else
#       name_text = link.to_s
#     end
#     member = people.find_member_by_name_current_on_date(Name.title_first_last(name_text), Date.today, House.senate)
#     if member.nil?
#       puts "WARNING: Can't find Senator #{link}"
#     else
#       data[member.person.id] = page.uri + link.uri
#     end
#   end
# end
#
# xml = File.open("#{conf.members_xml_path}/links-abc-qanda.xml", 'w')
# x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
# x.instruct!
# x.peopleinfo do
#   data.each do |id, link|
#     x.personinfo(:id => id, :mp_biography_qanda => link)
#   end
# end
# xml.close

puts "Register of interests from APH..."

base_url = "http://www.aph.gov.au/Parliamentary_Business/Committees/House_of_Representatives_Committees"
page = agent.get("#{base_url}?url=pmi/declarations.htm")

representatives_data = page.search("ul.links")[2].search(:li).map do |li|
  # A bit of wrangling to replace double spaces and things
  name_text = li.inner_text.strip.gsub("  ", " ").split(", Member")[0]

  representative = people.find_person_by_name(Name.last_title_first(name_text))
  raise if representative.nil?

  url = base_url + li.at(:a).attr(:href)

  { id: representative.id, aph_interests_url: url }
end

senate_data = []
base_url = "https://www.aph.gov.au/Parliamentary_Business/Committees/Senate/Senators_Interests/Register46thparl"
page = agent.get(base_url)

senate_data = page.at("#main_0_content_0_divContent").search("tr").map do |ul|
  senator = people.find_person_by_name(Name.last_title_first(ul.at(:a).inner_text.split(" - ").first))
  raise if senator.nil?

  url = page.uri + ul.at(:a).attr(:href)
  last_updated = Date.parse(ul.at(:em).inner_text.split(" Last updated ").last)

  { id: senator.id, aph_interests_url: url, aph_interests_last_updated: last_updated }
end

xml = File.open("#{conf.members_xml_path}/links-register-of-interests.xml", "w")
x = Builder::XmlMarkup.new(target: xml, indent: 1)
x.instruct!
x.peopleinfo do
  representatives_data.each do |representative|
    x.personinfo(id: representative[:id],
                 aph_interests_url: representative[:aph_interests_url])
  end
  senate_data.each do |senator|
    x.personinfo(id: senator[:id],
                 aph_interests_url: senator[:aph_interests_url],
                 aph_interests_last_updated: senator[:aph_interests_last_updated])
  end
end
xml.close

system("#{conf.web_root}/twfy/scripts/mpinfoin.pl links")

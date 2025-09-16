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

  puts "Election results 2022 (from the abc.net.au)..."
  abc_root = "https://www.abc.net.au"
  url = "#{abc_root}/news/elections/federal/2022/guide/electorates"
  doc = agent.get(url)

  doc.search("td.electorate a").each do |a|
    href = doc.uri + a["href"]
    name = a.inner_text.strip
    x.consinfo("canonical" => name, "abc_election_results_2022" => href)
  end

  %w[NSW Victoria Queensland WA SA Tasmania ACT NT].each do |canonical|
    # No seperate url for each state results... So...
    href = "https://www.abc.net.au/news/elections/federal/2022/results/senate"
    x.consinfo("canonical" => canonical, "abc_election_results_2022" => href)
  end
end
xml.close

puts "Register of interests from APH..."

page = agent.get("https://www.aph.gov.au/Senators_and_Members/Members/Register")
representatives_data = []
page.search("table.documents").each do |table|
  table.search("tbody tr").each do |tr|
    name = tr.search("td")[1].inner_text.split(",")[0..1].join(",")
    url = page.uri + tr.at("td.format a")["href"]
    name_obj = Name.last_title_first(name)
    representative = people.find_person_by_name_current_on_date(name_obj, Date.today)
    raise "Couldn't find #{name}. Try adding \"#{name_obj.title_first_last} \" to aliases" if representative.nil?

    representatives_data << { id: representative.id, aph_interests_url: url }
  end
end

senate_data = []

base_url = "https://www.aph.gov.au/Parliamentary_Business/Committees/Senate/Senators_Interests/Register_of_Senators_Interests"
page = agent.get(base_url)

page.at("table#currentRegisterTable tbody").search("tr").each do |tr|
  link = tr.at("a")
  name = link.inner_text.strip
  url = page.uri + link["href"]
  last_updated = Date.parse(tr.search("td")[2].inner_text)

  senator = people.find_person_by_name(Name.last_title_first(name))
  raise if senator.nil?

  senate_data << { id: senator.id, aph_interests_url: url, aph_interests_last_updated: last_updated }
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

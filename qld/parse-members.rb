#!/usr/bin/env ruby
#
# Download list of members from QLD Parliament house website

$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'mechanize_proxy'
agent = MechanizeProxy.new

#require 'rubygems'
#require 'mechanize'
#agent = WWW::Mechanize.new
#require 'nokogiri'
#require 'open-uri'
require 'uri'
require 'ostruct'
require 'name'
require 'csv'

members = []

('A'...'Z').each do |letter|
  url = "http://www.parliament.qld.gov.au/view/historical/records1860.asp?SubArea=register_#{letter}&SubNav=register_A"
  begin
    page = agent.get(url)
    #page = Nokogiri::HTML(open("http://www.parliament.qld.gov.au/view/historical/records1860.asp?SubArea=register_A")) 
  rescue WWW::Mechanize::ResponseCodeError => e
    puts "WARNING: Could not get member page for letter #{letter}. Skipping."
    next
  end

  page.search(".normal table").first.search("tr")[1..-1].each do |row|
    member = OpenStruct.new
    
    elements = []
    e = row.search("td")[0]
    # Remove badly formatted td tags that lie within td tags
    removed = e.search('td')
    removed.remove
    elements << e
    member.name = Name.last_title_first(elements[0].inner_text.strip)
    member.bio_url = URI.parse(url) + URI.parse(elements[0].at('a').attributes['href']) if elements[0].at('a')
    elements += removed
    elements += row.search("td")[1..-1]
    party_source = elements[1].inner_html.gsub("&nbsp;", "").strip
    parties_source = party_source.split(",")
    # Double check member parties
    valid_parties = [
      "ALP", 
      "City Country Alliance",
      "Communist",
      "Country National",
      "Country",
      "Democrat",
      "DLP",
      "Farmers' Representative",
      "Farmers' Union",
      "Independent",
      "Liberal National",
      "Liberal",
      "LNP",
      "Ministerialist",
      "National",
      "Nationalist",
      "Northern Country",
      "NQLP",
      "NQP",
      "One Nation",
      "Opposition",
      "Pauline Hanson's One Nation",
      "PPC",
      "Protestant Labour Party",
      "Qld People's Party",
      "QLP",
      "Queensland Greens",
      "UAP",
      "United",
    ]
    
    # Some workarounds for apparently inconsistent naming on the website
    party_exceptions = {
      "Country/National" => "Country National",
      "Independent Labour" => "Independent",
      "Independent Liberal" => "Independent",
      "Independent Democrat" => "Independent",
      "IND" => "Independent",
      "Independent (CEC)" => "Independent",
      "CityCountry Alliance" => "City Country Alliance",
      "Country.National" => "Country National",
      "County/National" => "Country National",
      "CountryNational" => "Country National",
      "One Nation (ON)" => "One Nation",
      "Qld. People's Party" => "Qld People's Party"
    }

    member.parties = parties_source.map do |party_source|
      party = party_source.strip
      party = party_exceptions[party] if party_exceptions[party]
      if party != "" && !valid_parties.include?(party)
        puts "WARNING: Unknown party: #{party} for #{member.name}"
      end
      party
    end
    terms = elements[2].inner_html.gsub("&nbsp;", "")
    member.date_ranges = terms.split("<br />").map do |term|
      if term =~ /^\s*(\d+\.\d+\.\d+)\s*-\s*(\d+\.\d+\.\d+)?( \(resigned\))?$/
        begin
          from_date = Date.parse($~[1])        
        rescue ArgumentError
          puts "WARNING: #{member.name} has invalid date in #{$~[1]}"
        end

        begin
          to_date = Date.parse($~[2]) if $~[2]
        rescue ArgumentError
          puts "WARNING: #{member.name} has invalid date in #{$~[2]}"
        end
      elsif term == ""
        from_date = nil
        to_date = nil
      else
        puts "WARNING: For #{member.name} ignoring the term '#{term}' because it's not in an expected form"
      end
      OpenStruct.new(:start => from_date, :end => to_date)
    end
    birth_text = elements[3].inner_html.gsub("&nbsp;", "").strip
    # Where the date of death or birth are just given as the year ignore those dates
    # At the moment it doesn't even spit out a warning because there are just too many occurences of this
    unless birth_text == "" || birth_text == "Unknown" || birth_text =~ /^\d{4}$/
      begin
        member.birth = Date.parse(birth_text)
      rescue ArgumentError
        puts "WARNING: #{member.name} has invalid date of birth of #{birth_text}"
      end
    end
    death_text = elements[4].inner_html.gsub("&nbsp;", "").strip
    unless death_text == "" || death_text =~ /^\d{4}$/
      begin
        member.death = Date.parse(death_text)
        #puts member.death
      rescue ArgumentError
        puts "WARNING: #{member.name} has invalid date of death of #{death_text}"
      end
    end
    members << member
  end
  
end

# Output a list of all the people in csv format
CSV.open('people.csv', 'w') do |writer|
  writer << ['last name', 'first name', 'middle names', 'birth_date', 'death_date']

  members.each do |m|
    writer << [m.name.last, m.name.first, (m.name.middle if m.name.middle != ""), m.birth, m.death]
  end
end


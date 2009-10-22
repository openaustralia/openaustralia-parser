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

page = agent.get("http://www.parliament.qld.gov.au/view/historical/records1860.asp?SubArea=register_A")
#page = Nokogiri::HTML(open("http://www.parliament.qld.gov.au/view/historical/records1860.asp?SubArea=register_A")) 

page.search(".normal table").first.search("tr")[1..-1].each do |row|
  elements = []
  e = row.search("td")[0]
  # Remove badly formatted td tags that lie within td tags
  removed = e.search('td')
  removed.remove
  elements << e
  name = elements[0].inner_text.strip
  #p name
  elements += removed
  elements += row.search("td")[1..-1]
  party = elements[1].inner_html.gsub("&nbsp;", "").strip
  term = elements[2].inner_html.gsub("&nbsp;", "")
  if term =~ /^(\d{2}.\d{2}.\d{4})\s*-\s*(\d{2}.\d{2}.\d{4})?$/
    from_date = $~[1]
    to_date = $~[2]
  elsif term == ""
    from_date = nil
    to_date = nil
  else
    puts "**** Ignoring the term '#{term}' because it's not in an expected form"
  end
  puts "name: #{name}, party: #{party}, from_date: #{from_date}, to_date: #{to_date}"
end
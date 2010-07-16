#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'rubygems'
require 'mechanize'
require 'configuration'
require 'people'

conf = Configuration.new

agent = WWW::Mechanize.new

puts "Reading Australia post office data..."
data = CSV.readlines("data/pc-full_20100629.csv")
# Ignore header
data.shift

valid_postcodes = data.map {|row| row.first}.uniq.sort

def extract_divisions_from_page(page)
  page.search('div/table/tr/td[4]').map {|t| t.inner_text}
end

def other_pages?(page)
  page.at('table table')
end

file = File.open("data/postcodes.csv", "w")

file.puts("Postcode,Electoral division name")
file.puts(",")

valid_postcodes.each do |postcode|
  page = agent.get("http://apps.aec.gov.au/esearch/LocalitySearchResults.aspx?filter=#{postcode}&filterby=Postcode")
  
  divisions = extract_divisions_from_page(page)

  if other_pages?(page)
    puts "WARNING: Multiple pages of data for postcode #{postcode}"
    file.puts("*** Double check data for postcode #{postcode} by hand ***")
  end
  
  if divisions.empty?
    puts "No divisions for postcode #{postcode}"
  else
    divisions.uniq.sort.each do |division|
      file.puts "#{postcode},#{division}"
    end
  end
end


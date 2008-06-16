#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'mechanize_proxy'
require 'configuration'
require 'people'

conf = Configuration.new

agent = MechanizeProxy.new
agent.cache_subdirectory = "parse-postcodes"

puts "Reading Australia post office data..."
data = CSV.readlines("data/pc-full_20080529.csv")
# Ignore header
data.shift

valid_postcodes = data.map {|row| row.first}.uniq.sort

def extract_divisions_from_page(page)
  postcodes = []
  page.search('table').first.search('> tr').each do |row_tag|
    td_tag = row_tag.search('> td')[3]
    if td_tag
      postcode = td_tag.search('a').inner_text
      if postcode.nil?
        puts "Nil postcode in division #{division}"
      end
      postcodes << postcode
    end
  end
  postcodes
end

def other_pages?(page)
  table_tag = page.search('table')[1]
  !table_tag.search('> tr > td > a').map {|e| e.inner_text}.empty?
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


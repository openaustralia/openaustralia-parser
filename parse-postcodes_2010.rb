#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'rubygems'
require 'mechanize'
require 'configuration'
require 'people'

conf = Configuration.new

agent = Mechanize.new

puts "Reading Australia post office data..."
data = CSV.readlines("data/pc-full_20100629.csv")
# Ignore header
data.shift

valid_postcodes = data.map { |row| row.first }.uniq.sort

def extract_divisions_from_page(page)
  divisions = page.search('div/table/tr/td[4]').map { |t| t.inner_text }
  redistributed_divisions = page.search('div/table/tr/td[5]').map { |t| t.inner_text }
  raise "expected same number of divisions as redistributed divisions" unless divisions.size == redistributed_divisions.size

  combined = []
  divisions.each_index do |i|
    v1 = divisions[i]
    v2 = redistributed_divisions[i]
    if v1 == ""
      combined << v2
    elsif v2 == ""
      combined << v1
    else
      raise "don't expect both columns to have values"
    end
  end
  combined
end

def other_pages?(page)
  page.at('table table')
end

def extract_divisions_for_postcode(agent, postcode)
  page = agent.get("http://apps.aec.gov.au/esearch/LocalitySearchResults.aspx?filter=#{postcode}&filterby=Postcode")
  puts "Postcode #{postcode}..."
  page_number = 1
  puts "  Page #{page_number}..."
  divisions = extract_divisions_from_page(page)

  if other_pages?(page)
    begin
      page_number += 1
      puts "  Page #{page_number}..."
      form = page.form_with(:name => "aspnetForm")
      form["__EVENTTARGET"] = 'ctl00$ContentPlaceHolderBody$gridViewLocalities'
      form["__EVENTARGUMENT"] = "Page$#{page_number}"
      page = form.submit
      new_divisions = extract_divisions_from_page(page)
      divisions += new_divisions
    end until new_divisions.empty?
  end
  # Remove duplicates and sort
  divisions.uniq.sort
end

file = File.open("data/postcodes_2010.csv", "w")

file.puts("Postcode,Electoral division name")
file.puts(",")

valid_postcodes.each do |postcode|
  divisions = extract_divisions_for_postcode(agent, postcode)

  if divisions.empty?
    puts "  * No divisions *"
  else
    puts "  " + divisions.join(", ")
    divisions.each do |division|
      file.puts "#{postcode},#{division}"
    end
  end
end

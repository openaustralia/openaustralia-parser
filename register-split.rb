#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'csv'
require 'name'
require 'people'

people = PeopleCSVReader.read_members

# Read in one split file
data = CSV.readlines('data/register_of_interests/senate/2008_sep_vol_1.split')
# Throw away first line (comment)
data.shift

data.each_index do |i|
  start_page, last_name, first_name = data[i]
  start_page = start_page.to_i
  if i + 1 < data.size
    end_page = data[i+1][0].to_i - 1
  else
    end_page = 'end'
  end
  # Ignore page ranges marked as blank
  if last_name.downcase != "** blank page **"
    name = Name.last_title_first(last_name + " " + first_name)
    member = people.find_member_by_name_current_on_date(name, Date.new(2008, 9, 1), House.senate)
    throw "Couldn't find senator #{name.full_name}" if member.nil?      
    puts "Start: #{start_page}, End: #{end_page}, Name: #{member.person.name.full_name}, id: #{member.person.id_count}"
  end
end


#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'configuration'
require 'people'
require 'enumerator'

conf = Configuration.new

system("mkdir -p #{conf.members_xml_path}")

# Copy across files that are needed for the script xml2db to run but are not yet populated with data
["bbc-links.xml", "constituencies.xml", "diocese-bishops.xml", "edm-links.xml", "expenses200102.xml",
  "expenses200203.xml", "expenses200304.xml", "expenses200405.xml", "expenses200506.xml", "expenses200506former.xml",
  "expenses200607.xml", "guardian-links.xml", "journa-list.xml", "lordbiogs.xml", "ni-members.xml",
  "royals.xml", "sp-members.xml", "wikipedia-commons.xml", "wikipedia-lords.xml", "wikipedia-mla.xml",
  "wikipedia-msp.xml"].each do |file|
    system("cp data/empty-template.xml #{conf.members_xml_path}/#{file}")
end

puts "Reading members data..."
people = People.read_members_csv("data/people.csv", "data/members.csv")
people.read_ministers_csv("data/ministers.csv")
people.read_ministers_csv("data/shadow-ministers.csv")
puts "Running consistency checks..."
# First check that each constituency is showing a continuous period of members with there never being more than one member at any time.
# Collect all the division names

members = people.all_house_periods
divisions = members.map {|member| member.division}.uniq.sort

# Electoral divisions that don't exist anymore
old_divisions = ["Angas", "Balaclava", "Bonython", "Burke", "Corinella", "Darling", "Darling Downs", "Diamond Valley",
  "Dundas", "Evans", "Gwydir", "Hawker", "Henty", "Namadgi", "Northern Territory", "Phillip", "Riverina-Darling", "St George",
  "Streeton", "Wilmot"]

divisions.each do |division|
  #puts "Checking division #{division}..."
  division_members = members.find_all { |member| member.division == division}.sort {|a,b| a.from_date <=> b.from_date}
  division_members.each do |member|
    #puts "  From: #{member.from_date} To: #{member.to_date} Member: #{member.person.name.full_name} Party: #{member.party}"
    throw "From and To date the wrong way round" unless member.from_date < member.to_date
  end
  division_members.each_cons(2) do |a,b|
    overlap = a.to_date - b.from_date
    if overlap > 0
      puts "ERROR: Members #{a.person.name.full_name} and #{b.person.name.full_name} both in at the same time (overlap by #{overlap} days)"
    end
  end
  unless old_divisions.member?(division) || division_members.any? {|m| m.current?}
    puts "WARNING: No current member for #{division}"
  end
  if division_members.first.from_date > Date.new(1980,1,1)
    #puts "WARNING: Earliest member in division #{division} is #{division_members.first.person.name.full_name} who started on #{division_members.first.from_date}"
  end
end

people.each do |person|
  person_members = person.periods.sort {|a,b| a.from_date <=> b.from_date}
  person_members.each_cons(2) do |a,b|
    overlap = a.to_date - b.from_date
    if overlap > 0
      puts "ERROR: #{person.name.full_name} has two periods that overlap (by #{overlap} days)"
    end
  end  
end

puts "Writing XML..."
people.write_xml("#{conf.members_xml_path}/people.xml", "#{conf.members_xml_path}/all-members.xml", "#{conf.members_xml_path}/peers-ucl.xml",
  "#{conf.members_xml_path}/ministers.xml")

# And load up the database
system("#{conf.web_root}/twfy/scripts/xml2db.pl --members --all --force")

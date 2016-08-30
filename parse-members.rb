#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'configuration'
require 'people'
require 'enumerator'

conf = Configuration.new

FileUtils.mkdir_p conf.members_xml_path

puts "Reading members data..."
people = PeopleCSVReader.read_members
PeopleCSVReader.read_all_ministers(people)
puts "Running consistency checks..."
# First check that each constituency is showing a continuous period of members with there never being more than one member at any time.
# Collect all the division names

members = people.all_periods_in_house(House.representatives)
divisions = members.map {|member| member.division}.uniq.sort

# Electoral divisions that don't exist anymore
old_divisions = ["Angas", "Balaclava", "Bonython", "Burke", "Corinella", "Darling", "Darling Downs", "Diamond Valley",
  "Dundas", "Evans", "Gwydir", "Hawker", "Henty", "Namadgi", "Northern Territory", "Phillip", "Riverina-Darling", "St George",
  "Streeton", "Wilmot", "Kalgoorlie", "Lowe", "Prospect", "Charlton"]

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
people.write_xml("#{conf.members_xml_path}/people.xml", "#{conf.members_xml_path}/representatives.xml", "#{conf.members_xml_path}/senators.xml",
  "#{conf.members_xml_path}/ministers.xml", "#{conf.members_xml_path}/divisions.xml")

# And load up the database
# Starts with 'perl' to be friendly with Windows
system("perl #{conf.web_root}/twfy/scripts/xml2db.pl --members --all --force")

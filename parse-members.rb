#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"

require "configuration"
require "people"
require "optparse"

# Defaults
options = { load_database: true }

OptionParser.new do |opts|
  opts.banner = "Usage: parse-members.rb [--no-load]"

  # This is useful when just testing whether the members data is well-formed
  # We do this as part of the tests on travis
  opts.on("--no-load", "Just generate XML and don't load up database") do |l|
    options[:load_database] = l
  end
end.parse!

# TODO: Fix this obscure parameter option for configuration
conf = Configuration.new(({} unless options[:load_database]))

FileUtils.mkdir_p conf.members_xml_path

puts "Reading members data..."
people = PeopleCSVReader.read_members
PeopleCSVReader.read_all_ministers(people)
puts "Running consistency checks..."
# First check that each constituency is showing a continuous period of members with there never being more than one member at any time.
# Collect all the division names

members = people.all_periods_in_house(House.representatives)
divisions = members.map(&:division).uniq.sort

# Electoral divisions that don't exist anymore
old_divisions = ["Angas", "Balaclava", "Bonython", "Burke", "Corinella", "Darling", "Darling Downs", "Diamond Valley",
                 "Dundas", "Evans", "Gwydir", "Hawker", "Henty", "Namadgi", "Northern Territory", "Phillip", "Riverina-Darling", "St George",
                 "Streeton", "Wilmot", "Kalgoorlie", "Lowe", "Prospect", "Charlton", "Fraser", "Throsby",
                 "Batman", "Denison", "McMillan", "Melbourne Ports", "Murray", "Port Adelaide", "Wakefield",
                 # Stirling was abolished for the 2022 Federal election
                 # See https://www.aec.gov.au/Electorates/Redistributions/2021/wa/announce-names-boundaries.htm
                 "Stirling"]

divisions.each do |division|
  # puts "Checking division #{division}..."
  division_members = members.find_all { |member| member.division == division }.sort { |a, b| a.from_date <=> b.from_date }
  division_members.each do |member|
    # puts "  From: #{member.from_date} To: #{member.to_date} Member: #{member.person.name.full_name} Party: #{member.party}"
    raise "From and To date the wrong way round" unless member.from_date < member.to_date
  end
  division_members.each_cons(2) do |a, b|
    overlap = a.to_date - b.from_date
    raise "ERROR: Members #{a.person.name.full_name} and #{b.person.name.full_name} both in at the same time (overlap by #{overlap} days)" if overlap.positive?
  end
  puts "WARNING: No current member for #{division}" unless old_divisions.member?(division) || division_members.any?(&:current?)
  if division_members.first.from_date > Date.new(1980, 1, 1)
    # puts "WARNING: Earliest member in division #{division} is #{division_members.first.person.name.full_name} who started on #{division_members.first.from_date}"
  end
end

people.each do |person|
  person_members = person.periods.sort { |a, b| a.from_date <=> b.from_date }
  person_members.each_cons(2) do |a, b|
    overlap = a.to_date - b.from_date
    raise "ERROR: #{person.name.full_name} has two periods that overlap (by #{overlap} days)" if overlap.positive?
  end
end

puts "Writing XML..."
people.write_xml("#{conf.members_xml_path}/people.xml", "#{conf.members_xml_path}/representatives.xml", "#{conf.members_xml_path}/senators.xml",
                 "#{conf.members_xml_path}/ministers.xml", "#{conf.members_xml_path}/divisions.xml")

if options[:load_database]
  # And load up the database
  # Starts with 'perl' to be friendly with Windows
  system("perl #{conf.web_root}/twfy/scripts/xml2db.pl --members --all --force")
else
  puts "Created xml files in #{conf.members_xml_path}"
end

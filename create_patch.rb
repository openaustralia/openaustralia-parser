#!/usr/bin/env ruby
# Create a patch easily for a particular date

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'environment'
require 'optparse'
require 'date'
require 'fileutils'
require 'people_csv_reader'
require 'hansard_parser'

OptionParser.new do |opts|
  opts.banner = <<EOF
Usage: create-patch.rb <reps|senate> <year.month.day>
EOF
end.parse!

if ARGV.size != 2
  puts "Wrong number of parameters"
  exit
end
    
if ARGV[0] == "reps" or ARGV[0] == "representatives"
  house = House.representatives
elsif ARGV[0] == "senate"
  house = House.senate
else
  puts "Expected 'reps' or 'senate' for first parameter"
  exit
end

date = Date.parse(ARGV[1])

# For the time being just edit the representatives

people = PeopleCSVReader.read_members
parser = HansardParser.new(people)

# First check that there isn't already a patch file
patch_file_path = "#{File.dirname(__FILE__)}/data/patches/#{house}.#{date}.xml.patch"

# These get really different results (I think becuase of the rewriter). I can't
# be bothered to work it out right now so I'm just doing the below instead
# File.open("original.xml", "w") {|f| f << parser.unpatched_hansard_xml_source_data_on_date(date, house)}
# File.open("patched.xml", "w") {|f| f << parser.hansard_xml_source_data_on_date(date, house)}
File.open("original.xml", "w") {|f| f << parser.hansard_xml_source_data_on_date(date, house)}
FileUtils.cp 'original.xml', 'patched.xml'

system("vim patched.xml")
system("diff -u original.xml patched.xml >> #{patch_file_path}")

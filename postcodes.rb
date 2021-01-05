#!/usr/bin/env ruby
# Load the postcode data directly into the database

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'rubygems'
require 'csv'
require 'mysql2'
require 'configuration'
require 'people'
require 'optparse'

options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: postcodes.rb [--test]"

  opts.on("--test", "Run in test mode (no DB updates)") do |test|
    options[:test] = test
  end
end.parse!

unless options[:test]
  conf = Configuration.new
end

def quote_string(s)
  s.gsub(/\\/, '\&\&').gsub(/'/, "''") # ' (for ruby-mode)
end

data = CSV.readlines("data/postcodes.csv")
# Remove headers
data.shift

puts "Reading members data..."
people = PeopleCSVReader.read_members
all_members = people.all_periods_in_house(House.representatives)

# First check that all the constituencies are valid
constituencies = data.map { |row| row[1] }.uniq.reject(&:empty?)
constituencies.each do |constituency|
  raise "Constituency #{constituency} not found" unless all_members.any? { |m| m.division == constituency }
end

if options[:test]
  puts "Postcodes look good!"
else
  db = Mysql2::Client.new(:host => conf.database_host, :username => conf.database_user, :password => conf.database_password, :database => conf.database_name)

  # Clear out the old data
  db.query("DELETE FROM postcode_lookup")

  values = data.map { |row| "('#{row[0]}', '#{quote_string(row[1])}')" }.join(',')
  db.query("INSERT INTO postcode_lookup (postcode, name) VALUES #{values}")
end

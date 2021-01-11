#!/usr/bin/env ruby
# frozen_string_literal: true

# Load the postcode data directly into the database

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"

require "rubygems"
require "csv"
require "mysql2"
require "configuration"
require "people"
require "optparse"

# Defaults
options = { load_database: true }

OptionParser.new do |opts|
  opts.banner = "Usage: postcodes.rb [--no-load]"

  opts.on("--no-load", "Just generate XML and don't load up database") do |l|
    options[:load_database] = l
  end
end.parse!

def quote_string(text)
  text.gsub(/\\/, '\&\&').gsub(/'/, "''") # ' (for ruby-mode)
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

if options[:load_database]
  conf = Configuration.new
  db = Mysql2::Client.new(host: conf.database_host, username: conf.database_user, password: conf.database_password,
                          database: conf.database_name)

  # Clear out the old data
  db.query("DELETE FROM postcode_lookup")

  values = data.map { |row| "('#{row[0]}', '#{quote_string(row[1])}')" }.join(",")
  db.query("INSERT INTO postcode_lookup (postcode, name) VALUES #{values}")
end

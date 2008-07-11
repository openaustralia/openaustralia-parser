#!/usr/bin/env ruby
# Load the postcode data directly into the database

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'rubygems'
require 'csv'
require 'mysql'
require 'configuration'
require 'people'

conf = Configuration.new

def quote_string(s)
  s.gsub(/\\/, '\&\&').gsub(/'/, "''") # ' (for ruby-mode)
end

data = CSV.readlines("data/postcodes.csv")
# Remove the first two elements
data.shift
data.shift

puts "Reading members data..."
people = People.read_members_csv("data/people.csv", "data/members.csv")
all_members = people.all_periods_in_house(House.representatives)

# First check that all the constituencies are valid
constituencies = data.map { |row| row[1] }.uniq
constituencies.each do |constituency|
  throw "Constituency #{constituency} not found" unless all_members.any? {|m| m.division == constituency}
end

db = Mysql.real_connect(conf.database_host, conf.database_user, conf.database_password, conf.database_name)

# Clear out the old data
db.query("DELETE FROM postcode_lookup")

values = data.map {|row| "('#{row[0]}', '#{quote_string(row[1])}')" }.join(',')
db.query("INSERT INTO postcode_lookup (postcode, name) VALUES #{values}")

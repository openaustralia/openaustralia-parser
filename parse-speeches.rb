#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'people'
require 'hansard_parser'
require 'configuration'

conf = Configuration.new

system("mkdir -p #{conf.xml_path}/scrapedxml/debates")
system("mkdir -p #{conf.xml_path}/scrapedxml/regmem")

# Copy across file that is needed for the script xml2db to run but is not yet populated with data
system("cp data/empty-template.xml #{conf.xml_path}/scrapedxml/regmem/regmem2000-01-01.xml")

# First load people back in so that we can look up member id's
people = People.read_csv("data/members.csv", "data/ministers.csv")

# Interesting dates:
# Last day of 2007 parliament: 2007.9.20)
# First day of 2008 parliament: 2008.2.12
#
# Problem dates:
# 2007.6.18: President speaks: 2007.6.18
# 2007.6.21: Multiple matches for name Hon. BK Bishop found
# 2007.9.11: No match for name Rt Hon. STEPHEN HARPER found
#
#from_date = Date.new(2008, 3, 28)
#to_date = Date.today
from_date = Date.new(2008, 2, 12)
to_date = Date.new(2008, 3, 18)

date = from_date
while date <= to_date
  puts "Parsing speeches for #{date.strftime('%a %d %b %Y')}..."
  HansardParser.parse_date(date, "#{conf.xml_path}/scrapedxml/debates/debates#{date}.xml", people)
  date = date + 1
end

# And load up the database
system(conf.web_root + "/twfy/scripts/xml2db.pl --debates --all --force")

#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'people'
require 'hansard_parser'
require 'configuration'

# First load people back in so that we can look up member id's
people = People.read_csv("data/members.csv", "data/ministers.csv")

system("mkdir -p pwdata/scrapedxml/debates")

date = Date.new(2007, 9, 20)
xml_filename = "pwdata/scrapedxml/debates/debates#{date}.xml"

HansardParser.parse_date(date, xml_filename, people)

# Temporary hack: nicely indent XML
system("tidy -quiet -indent -xml -modify -wrap 0 -utf8 #{xml_filename}")

conf = Configuration.new

# And load up the database
system(conf.web_root + "/twfy/scripts/xml2db.pl --debates --all --force")

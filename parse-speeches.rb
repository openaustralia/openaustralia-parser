#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'people'
require 'hansard_parser'
require 'configuration'

conf = Configuration.new

system("mkdir -p #{conf.web_root}/pwdata/scrapedxml/debates")
system("mkdir -p #{conf.web_root}/pwdata/scrapedxml/regmem")

# Copy across file that is needed for the script xml2db to run but is not yet populated with data
system("cp data/empty-template.xml #{conf.web_root}/pwdata/scrapedxml/regmem/regmem2000-01-01.xml")

# First load people back in so that we can look up member id's
people = People.read_csv("data/members.csv", "data/ministers_new.csv")

date = Date.new(2007, 9, 20)
xml_filename = "#{conf.web_root}/pwdata/scrapedxml/debates/debates#{date}.xml"

HansardParser.parse_date(date, xml_filename, people)

# Temporary hack: nicely indent XML
system("tidy -quiet -indent -xml -modify -wrap 0 -utf8 #{xml_filename}")

# And load up the database
system(conf.web_root + "/twfy/scripts/xml2db.pl --debates --all --force")

#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'configuration'
require 'people'

conf = Configuration.new

system("mkdir -p #{conf.web_root}/pwdata/members")

# Copy across files that are needed for the script xml2db to run but are not yet populated with data
["bbc-links.xml", "constituencies.xml", "diocese-bishops.xml", "edm-links.xml", "expenses200102.xml",
  "expenses200203.xml", "expenses200304.xml", "expenses200405.xml", "expenses200506.xml", "expenses200506former.xml",
  "expenses200607.xml", "guardian-links.xml", "journa-list.xml", "lordbiogs.xml", "ni-members.xml", "peers-ucl.xml",
  "royals.xml", "sp-members.xml", "websites.xml", "wikipedia-commons.xml", "wikipedia-lords.xml", "wikipedia-mla.xml",
  "wikipedia-msp.xml"].each do |file|
    system("cp data/empty-template.xml #{conf.web_root}/pwdata/members/#{file}")
end

puts "Writing XML..."
people = People.read_csv("data/members.csv", "data/ministers.csv")
people.write_xml("#{conf.web_root}/pwdata/members/people.xml", "#{conf.web_root}/pwdata/members/all-members.xml",
  "#{conf.web_root}/pwdata/members/ministers.xml")

puts "Downloading person images..."
people.download_images("#{conf.web_root}/twfy/www/docs/images/mps", "#{conf.web_root}/twfy/www/docs/images/mpsL")

# And load up the database
system("#{conf.web_root}/twfy/scripts/xml2db.pl --members --all --force")

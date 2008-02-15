#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'configuration'

require 'people_csv_reader'
require 'people_xml_writer'
require 'people_image_downloader'

puts "Writing XML..."
people = PeopleCSVReader.read("data/house_members.csv")
PeopleXMLWriter.write_people(people, 'pwdata/members/people.xml')
PeopleXMLWriter.write_members(people, 'pwdata/members/all-members.xml')

puts "Downloading person images..."
downloader = PeopleImageDownloader.new
downloader.download(people, "pwdata/images/mps", "pwdata/images/mpsL")

# And load up the database
conf = Configuration.new
system(conf.web_root + "/twfy/scripts/xml2db.pl --members --all --force")
image_dir = conf.web_root + "/twfy/www/docs/images"
system("rm -rf " + image_dir + "/mps/*.jpg " + image_dir + "/mpsL/*.jpg")
system("cp -R pwdata/images/* " + image_dir)

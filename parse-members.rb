#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'configuration'
require 'people'

puts "Writing XML..."
people = People.read_csv("data/house_members.csv")
people.write_people_xml('pwdata/members/people.xml')
people.write_members_xml('pwdata/members/all-members.xml')

puts "Downloading person images..."
people.download_images("pwdata/images/mps", "pwdata/images/mpsL")

# And load up the database
conf = Configuration.new
system(conf.web_root + "/twfy/scripts/xml2db.pl --members --all --force")
image_dir = conf.web_root + "/twfy/www/docs/images"
system("rm -rf " + image_dir + "/mps/*.jpg " + image_dir + "/mpsL/*.jpg")
system("cp -R pwdata/images/* " + image_dir)

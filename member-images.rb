#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'configuration'
require 'people'

conf = Configuration.new

people = People.read_members_csv("data/people.csv", "data/members.csv")
puts "Downloading person images..."
people.download_images("#{conf.file_image_path}/mps", "#{conf.file_image_path}/mpsL")

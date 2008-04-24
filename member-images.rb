#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'configuration'
require 'people'

conf = Configuration.new

people = People.read_csv("data/members.csv", "data/ministers.csv")
puts "Downloading person images..."
people.download_images("#{conf.file_image_path}/mps", "#{conf.file_image_path}/mpsL")

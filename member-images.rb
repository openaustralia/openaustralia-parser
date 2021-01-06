#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"

require "configuration"
require "people"

conf = Configuration.new

people = PeopleCSVReader.read_members
puts "Downloading person images..."
people.download_images("#{conf.file_image_path}/mps", "#{conf.file_image_path}/mpsL")

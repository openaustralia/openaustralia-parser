#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"

require "configuration"
require "people"

class MemberImages
  def initialize(args)
    @args = args
  end

  def run
    conf = Configuration.new
    people = PeopleCSVReader.read_members
    puts "Downloading person images..."
    people.download_images(
      "#{conf.file_image_path}/mps",
      "#{conf.file_image_path}/mpsL",
      "#{conf.file_image_path}/mpsXL"
    )
    puts "Finished downloading person images!"
  end
end

MemberImages.new(ARGV).run if $PROGRAM_NAME == __FILE__

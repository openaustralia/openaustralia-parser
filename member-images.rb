#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"

require "optparse"
require "configuration"
require "people"

class MemberImages
  def initialize(args)
    @args = args
    @options = { limit: nil }
    OptionParser.new do |opts|
      opts.banner = "Usage: member-images.rb [--limit=N] [--output-dir=PATH]"
      opts.on("--limit=N", Integer, "Cap the number of people whose images are downloaded") do |n|
        @options[:limit] = n
      end
      opts.on("--output-dir=PATH", "Download images to PATH instead of conf.file_image_path") do |path|
        @options[:output_dir] = path
      end
    end.parse!(@args)
  end

  def run
    conf = Configuration.new
    people = PeopleCSVReader.read_members
    file_image_path = @options[:output_dir] || conf.file_image_path
    FileUtils.mkdir_p ["#{file_image_path}/mps",
                       "#{file_image_path}/mpsL",
                       "#{file_image_path}/mpsXL"]
    puts "Downloading person images to #{file_image_path}/{mps,mpsL,mpsXL}..."
    people.download_images(
      "#{file_image_path}/mps",
      "#{file_image_path}/mpsL",
      "#{file_image_path}/mpsXL",
      limit: @options[:limit]
    )
    puts "Finished downloading person images!"
  end
end

MemberImages.new(ARGV).run if $PROGRAM_NAME == __FILE__



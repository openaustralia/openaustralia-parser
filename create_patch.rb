#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"

# Create a patch easily for a particular date

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"

require "optparse"
require "date"
require "fileutils"

require "people_csv_reader"
require "hansard_parser"

class CreatePatch
  def initialize(args)
    @args = args
  end

  def run
    OptionParser.new do |opts|
      opts.banner = <<~USAGE
        Usage: create-patch.rb <reps|senate> <year.month.day>
      USAGE
    end.parse!(@args)

    if @args.size != 2
      puts "Wrong number of parameters"
      return 1
    end

    case @args[0]
    when "reps", "representatives"
      house = House.representatives
    when "senate"
      house = House.senate
    else
      puts "Expected 'reps' or 'senate' for first parameter"
      return 1
    end

    date = Date.parse(@args[1])

    # For the time being just edit the representatives

    people = PeopleCSVReader.read_members
    parser = HansardParser.new(people)

    # First check that there isn't already a patch file
    patch_file_path = "#{File.dirname(__FILE__)}/data/patches/#{house}.#{date}.xml.patch"

    # These get really different results (I think because of the rewriter). I can't
    # be bothered to work it out right now so I'm just doing the below instead
    # File.open("original.xml", "w") {|f| f << parser.unpatched_hansard_xml_source_data_on_date(date, house)}
    # File.open("patched.xml", "w") {|f| f << parser.hansard_xml_source_data_on_date(date, house)}
    File.open("original.xml", "w") { |f| f << parser.hansard_xml_source_data_on_date(date, house) }
    puts "WARNING: original.xml is empty!" unless File.size?("original.xml")
    FileUtils.cp "original.xml", "patched.xml"

    $stdout.puts "Edit patched.xml to your liking, then:"
    $stdout.puts "diff -u original.xml patched.xml \>\> #{patch_file_path}"
    0
  end
end

exit CreatePatch.new(ARGV).run if $PROGRAM_NAME == __FILE__

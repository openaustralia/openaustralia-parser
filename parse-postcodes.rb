#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"

require "optparse"
require "fileutils"
require "mechanize"

require "configuration"

class ParsePostcodes
  def initialize(args)
    @args = args
    @options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: parse-postcodes.rb [--output-dir=PATH] [--morph-api-key=KEY]"
      opts.on("--output-dir=PATH", "Write postcodes.csv to this dir instead of data/") do |path|
        @options[:output_dir] = path
      end
      opts.on("--morph-api-key=KEY", "Override Morph.io API key") do |key|
        @options[:morph_api_key] = key
      end
    end.parse!(@args)
  end

  def run
    conf = Configuration.new

    morph_api_key = @options[:morph_api_key] || conf.morph_api_key
    output_dir = @options[:output_dir] || "data"
    data_filename = "#{output_dir}/postcodes.csv"

    puts "Fetching postcodes from morph.io ..."
    if morph_api_key.nil? || morph_api_key =~ /\AX*\z/
      puts "WARNING: morph_api_key is not set in configuration.yml! The api call will fail!"
    end

    FileUtils.mkdir_p output_dir

    sql_query = "SELECT DISTINCT postcode,COALESCE(NULLIF(electorate,''),redistributedElectorate) AS electorate FROM 'data' order by postcode,electorate"
    url = "https://api.morph.io/drzax/morph-division-postcode-correspondence/data.csv"

    agent = Mechanize.new
    response = agent.get(url, { key: morph_api_key, query: sql_query })

    raise "HTTP ERROR: #{response.code} fetching postcodes — check your morph.io API key" if response.code != "200"
    raise "ERROR: Empty response — check your morph.io API key" if response.body.strip.empty?

    puts "Saving to #{data_filename} ..."
    File.write(data_filename, response.body)
    puts "Done."
  end
end

exit ParsePostcodes.new(ARGV).run.to_i if $PROGRAM_NAME == __FILE__

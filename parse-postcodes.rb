#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"

require "optparse"
require "cgi"
require "fileutils"

require "configuration"

class ParsePostcodes
  def initialize(args)
    @args = args
    @options = { }
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
    output_dir = @options[:output_dir] || 'data'
    new_filename ="#{output_dir}/postcodes.csv.new"
    data_filename = "#{output_dir}/postcodes.csv"

    puts "Fetching postcodes from morph.io to #{new_filename} ..."
    if morph_api_key.nil? || morph_api_key =~ /\AX*\z/
      puts "WARNING: morph_api_key is not set in configuration.yml! The api call will fail!"
    end

    FileUtils.rm_f new_filename
    FileUtils.mkdir_p output_dir
    sql_query = CGI.escape "SELECT DISTINCT postcode,COALESCE(NULLIF(electorate,''),redistributedElectorate) FROM 'data'"
    url = "https://api.morph.io/drzax/morph-division-postcode-correspondence/data.csv?key=#{morph_api_key}&query=#{sql_query}"
    status_code = `curl --silent --output "#{new_filename}" --write-out "%{http_code}" "#{url}"`

    raise "ERROR: curl exited with status: #{$CHILD_STATUS.exitstatus}" if $CHILD_STATUS.exitstatus != 0
    raise "HTTP ERROR: #{status_code} fetching postcodes — check your morph.io API key" if status_code != "200"
    raise "ERROR: Empty response — check your morph.io API key" unless File.size?(new_filename)

    puts "Moving #{new_filename} to #{data_filename} ..."
    FileUtils.mv(new_filename, data_filename, force: true)
    puts "Done."
  end
end

ParsePostcodes.new(ARGV).run if $PROGRAM_NAME == __FILE__

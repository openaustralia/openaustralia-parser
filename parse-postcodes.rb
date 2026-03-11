#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"

require "rubygems"
require "cgi"

require "configuration"

class ParsePostcodes
  def initialize(args)
    @args = args
  end

  def run
    conf = Configuration.new

    puts "Fetching postcodes from morph.io..."

    sql_query = CGI.escape "SELECT DISTINCT postcode,COALESCE(NULLIF(electorate,''),redistributedElectorate) FROM 'data'"

    `curl --silent --output data/postcodes.csv "https://api.morph.io/drzax/morph-division-postcode-correspondence/data.csv?key=#{conf.morph_api_key}&query=#{sql_query}"`

    puts "Done."
  end
end

ParsePostcodes.new(ARGV).run if $PROGRAM_NAME == __FILE__

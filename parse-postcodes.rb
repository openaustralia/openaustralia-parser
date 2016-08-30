#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'rubygems'
require 'configuration'

conf = Configuration.new

puts "Fetching postcodes from morph.io..."

`curl --silent --output data/postcodes.csv "https://api.morph.io/drzax/morph-division-postcode-correspondence/data.csv?key=#{conf.morph_api_key}&query=select%20distinct%20postcode%2Celectorate%20from%20'data'"`

puts "Done."

#!/usr/bin/env ruby
# frozen_string_literal: true

###################
# Outputs PHP for the web app to display the latest policies from They Vote For You
# Put the resulting code here https://github.com/openaustralia/twfy/blob/22ee1bb460554a6db5428f269e779e57997b1225/www/includes/easyparliament/page.php#L1632-L1664
# No longer needed once we fix https://github.com/openaustralia/openaustralia/issues/545
$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"
require "open-uri"
require "openssl"
require "json"

require "configuration"

class TvfyPoliciesToPhp
  def initialize(args)
    @args = args
  end

  def run
    conf = Configuration.new

    if conf.theyvoteforyou_api_key.nil? || conf.theyvoteforyou_api_key =~ /\AX*\z/
      puts "WARNING: theyvoteforyou_api_key is not set in configuration.yml! The api call will fail!"
    end

    url = "https://theyvoteforyou.org.au/api/v1/policies.json?key=#{conf.theyvoteforyou_api_key}"

    # Ruby 1.8.7 doesn't like our SNI certificate :(
    policies = URI.open(url, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE) do |f|
      JSON.parse(f.read)
    end

    policies.each do |policy|
      next if policy["provisional"]

      puts "$got_dream |= display_dream_comparison($extra_info, $member, #{policy['id']}, \"#{policy['name'].gsub('"', '\"')}\", false, \"\");"
    end
  end
end

exit TvfyPoliciesToPhp.new(ARGV).run if $PROGRAM_NAME == __FILE__

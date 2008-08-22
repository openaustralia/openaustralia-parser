#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'date'
require 'hansard_parser'
require 'people'
require 'optparse'
require 'configuration'

def check_proof_status(date, house, delete_html_cache)
  # Hmm. Not very nice
  parser = HansardParser.new(People.new)
  conf = Configuration.new
  
  if parser.has_subpages_in_proof?(date, house)
    if delete_html_cache
      puts "Deleting all cached html for #{date} because at least one sub page is in proof stage."
      FileUtils.rm_rf("#{conf.html_cache_path}/#{parser.cache_subdirectory(date, house)}")
      puts "Redownloading and checking the pages for #{date}"
      check_proof_status(date, house, false)
      return
    else
      puts "One or more pages on #{date} are in proof stage"
    end
  end
end

# Defaults
options = {:delete_html_cache => false}

OptionParser.new do |opts|
  opts.banner = <<EOF
Usage: check-proof-status.rb [options] <from-date> [<to-date>]
  Report the proof status of Representatives and Senate pages on the given dates
    formatting of date:
      year.month.day
EOF
  opts.on("--delete-html-cache", "If page is a proof delete its html cache so that next time around it's reloaded from aph.gov.au") do |l|
    options[:delete_html_cache] = l
  end
end.parse!

if ARGV.size != 1 && ARGV.size != 2
  puts "Need to supply one or two dates"
  exit
end
    
from_date = Date.parse(ARGV[0])

if ARGV.size == 1
  to_date = from_date
else
  to_date = Date.parse(ARGV[1])
end


# Because pages still in proof stage are likely to occur recently we'll start
# at the end date and work backwards
date = to_date
while date >= from_date
  puts "Checking proof status for #{date}..."
  check_proof_status(date, House.representatives, options[:delete_html_cache])
  check_proof_status(date, House.senate, options[:delete_html_cache])
  date = date - 1
end

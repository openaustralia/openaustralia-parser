#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'date'
require 'hansard_parser'
require 'people'

def check_proof_status(date, house)
  # Hmm. Not very nice
  parser = HansardParser.new(People.new)

  parser.each_page_on_date(date, house) do |link, sub_page|
    proof = parser.extract_metadata_tags(sub_page)["Proof"]
    throw "Unexpected value '#{proof}' for metadata 'Proof'" unless proof == "Yes" || proof == "No"
    proof = (proof == "Yes")
    url = parser.extract_permanent_url(sub_page)
    puts "Page #{url} is in proof stage" if proof
  end
end

from_date = Date.new(2006, 1, 1)
to_date = Date.new(2008, 8, 22)


# Because pages still in proof stage are likely to occur recently we'll start
# at the end date and work backwards
date = to_date
while date >= from_date
  puts "Checking proof status for #{date}..."
  check_proof_status(date, House.representatives)
  check_proof_status(date, House.senate)
  date = date - 1
end

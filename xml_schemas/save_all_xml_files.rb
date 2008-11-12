#!/usr/bin/env ruby
# Saves all source XML data for 2007 into the directory "source". This is used to test the grammar aph-xml.rnc against

$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'hansard_parser'

from = Date.new(2007, 1, 1)
to = Date.new(2008, 1, 1) - 1

# Don't need to set 'people'
parser = HansardParser.new(nil)

FileUtils.mkdir_p "source"

(from..to).each do |date|
  puts "Downloading and saving XML data for #{date}..."
  text = parser.hansard_xml_source_data_on_date(date, House.representatives)
  File.open("source/#{date}-reps.xml", 'w') {|f| f << text } if text
  text = parser.hansard_xml_source_data_on_date(date, House.senate)
  File.open("source/#{date}-senate.xml", 'w') {|f| f << text } if text
end

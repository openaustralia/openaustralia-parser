#!/usr/bin/env ruby
# Saves all source XML data for 2007 into the directory "source". This is used to test the grammar aph-xml.rnc against

$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'hansard_parser'

from = Date.new(2006, 1, 1)
to = Date.new(2008, 1, 1) - 1

# Don't need to set 'people'
parser = HansardParser.new(nil)

FileUtils.mkdir_p "source"

def write_tidied_xml(text, filename)
  File.open(filename, 'w') {|f| f << text }
  system("tidy -q -i -w 200 -xml -utf8 -o #{filename} #{filename}")
end

(from..to).each do |date|
  puts "Downloading and saving XML data for #{date}..."
  text = parser.hansard_xml_source_data_on_date(date, House.representatives)
  write_tidied_xml(text, "source/#{date}-reps.xml") if text
  text = parser.hansard_xml_source_data_on_date(date, House.senate)
  write_tidied_xml(text, "source/#{date}-senate.xml") if text
end



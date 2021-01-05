#!/usr/bin/env ruby
# Saves source XML data into the directory "source". This is used to test the grammar aph-xml.rnc against

$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'hansard_parser'

from = Date.new(2005, 1, 1)
to = Date.new(2008, 1, 1) - 1

FileUtils.mkdir_p "source/2.0"
FileUtils.mkdir_p "source/2.1"

def write_tidied_xml(text, filename)
  File.open(filename, 'w') { |f| f << text }
  system("tidy -q -i -w 200 -xml -utf8 -o #{filename} #{filename}")
end

def write_hansard_xml_source_data_on_date(date, house)
  # Don't need to set 'people'
  parser = HansardParser.new(nil)

  text = parser.hansard_xml_source_data_on_date(date, house)
  if text
    # Figure out which version of the schema this file is using and save it into a directory based on that
    version = Hpricot.XML(text).at('hansard').attributes['version']
    raise "Unrecognised schema version #{version}" if version != "2.0" && version != "2.1"

    write_tidied_xml(text, "source/#{version}/#{date}-#{house.representatives? ? "reps" : "senate"}.xml")
  end
end

(from..to).each do |date|
  puts "Downloading and saving XML data for #{date}..."
  write_hansard_xml_source_data_on_date(date, House.representatives)
  write_hansard_xml_source_data_on_date(date, House.senate)
end

#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'people'
require 'hansard_parser'
require 'configuration'
require 'optparse'

def parse_date(text)
  today = Date.today
  
  if text == "today"
    today
  elsif text == "yesterday"
    today - 1
  elsif text == "previous-working-day"
    # For Sunday (wday 0) and Monday (wday 1) the previous working day is last Friday otherwise it's
    # just the previous day
    if today.wday == 0
      today - 2
    elsif today.wday == 1
      today - 3
    else
      today - 1
    end
  else
    Date.parse(text)
  end
end

# Defaults
options = {:load_database => true}

OptionParser.new do |opts|
  opts.banner = <<EOF
Usage: parse-speeches.rb [options] <from-date> [<to-date>]
    formatting of date:
      year.month.day or today or yesterday
    
    Interesting dates:
      Last day of 2007 parliament: 2007.9.20
      First day of 2008 parliament: 2008.2.12
    Problem dates:
      2007.6.18: President speaks: 2007.6.18
      2007.9.11: No match for name Rt Hon. STEPHEN HARPER found

EOF
  opts.on("--no-load", "Just generate XML and don't load up database") do |l|
    options[:load_database] = l
  end
end.parse!

if ARGV.size != 1 && ARGV.size != 2
  puts "Need to supply one or two dates"
  exit
end
    
from_date = parse_date(ARGV[0])

if ARGV.size == 1
  to_date = from_date
else
  to_date = parse_date(ARGV[1])
end

conf = Configuration.new

FileUtils.mkdir_p "#{conf.xml_path}/scrapedxml/debates"
FileUtils.mkdir_p "#{conf.xml_path}/scrapedxml/regmem"

# Copy across file that is needed for the script xml2db to run but is not yet populated with data
system("cp #{File.dirname(__FILE__)}/data/empty-template.xml #{conf.xml_path}/scrapedxml/regmem/regmem2000-01-01.xml")

# First load people back in so that we can look up member id's
people = PeopleCSVReader.read_members

parser = HansardParser.new(people)

date = from_date
while date <= to_date
  if conf.write_xml_representatives
    parser.parse_date_house(date, "#{conf.xml_path}/scrapedxml/debates/debates#{date}.xml", House.representatives)
  end
  if conf.write_xml_senators
    parser.parse_date_house(date, "#{conf.xml_path}/scrapedxml/lordspages/daylord#{date}.xml", House.senate)
  end
  date = date + 1
end

# And load up the database
houses_options = ""
houses_options = houses_options + " --debates" if conf.write_xml_representatives
houses_options = houses_options + " --lordsdebates" if conf.write_xml_senators

# Starts with 'perl' to be friendly with Windows
system("perl #{conf.web_root}/twfy/scripts/xml2db.pl #{houses_options} --from=#{from_date} --to=#{to_date} --force") if options[:load_database]

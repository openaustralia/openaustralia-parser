#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'people'
require 'hansard_parser'
require 'configuration'
require 'optparse'
require 'progressbar'

def parse_date(text)
  today = Date.today

  case text
  when "today"
    today
  when "yesterday"
    today - 1
  when "previous-working-day"
    # For Sunday (wday 0) and Monday (wday 1) the previous working day is last Friday otherwise it's
    # just the previous day
    case today.wday
    when 0
      today - 2
    when 1
      today - 3
    else
      today - 1
    end
  else
    Date.parse(text)
  end
end

# Defaults
options = { load_database: true, proof: false, force: false, interactive: false }

OptionParser.new do |opts|
  opts.banner = <<~EOF
    Usage: parse-speeches.rb [options] <from-date> [<to-date>]
        formatting of date:
          year.month.day or today or yesterday
  EOF
  opts.on("--no-load", "Just generate XML and don't load up database") do |l|
    options[:load_database] = l
  end
  opts.on("--interactive", "Upon error, allow the user to patch interactively") do |l|
    options[:interactive] = l
  end
  opts.on("--proof", "Only parse dates that are at proof stage. Will redownload and populate html cache for those dates.") do |l|
    options[:proof] = l
  end
  opts.on("--force", "On loading data into database delete records that are not in the XML") do |l|
    options[:force] = l
  end
end.parse!

if ARGV.size != 1 && ARGV.size != 2
  puts "Need to supply one or two dates"
  exit
end

from_date = parse_date(ARGV[0])

to_date = if ARGV.size == 1
            from_date
          else
            parse_date(ARGV[1])
          end

conf = Configuration.new

FileUtils.mkdir_p "#{conf.xml_path}/origxml/representatives_debates"
FileUtils.mkdir_p "#{conf.xml_path}/origxml/senate_debates"
FileUtils.mkdir_p "#{conf.xml_path}/rewritexml/representatives_debates"
FileUtils.mkdir_p "#{conf.xml_path}/rewritexml/senate_debates"
FileUtils.mkdir_p "#{conf.xml_path}/scrapedxml/representatives_debates"
FileUtils.mkdir_p "#{conf.xml_path}/scrapedxml/senate_debates"

# First load people back in so that we can look up member id's
people = PeopleCSVReader.read_members

parser = HansardParser.new(people)

progress = ProgressBar.new("parse-speeches", ((to_date - from_date + 1) * 2).to_i)

def parse_with_retry(interactive, parse, date, path, house)
  begin
    parse.call date, path, house
  rescue Exception => e
    puts "ERROR While processing #{house} #{date}:"
    raise unless interactive

    puts e.message
    puts e.backtrace.join("\n\t")
    loop do
      print "Retry / Patch / Continue / Quit? "
      choice = STDIN.gets.upcase[0..0]
      case choice
      when "P"
        system "#{File.dirname(__FILE__)}/create_patch.rb #{house} #{date}"
        parse_with_retry interactive, parse, date, path, house
        break
      when "R"
        parse_with_retry interactive, parse, date, path, house
        break
      when "C"
        break
      when "Q"
        raise
      end
    end
  end
end

# Kind of helpful to start at the end date and go backwards when using the "--proof" option. So, always going to do this now.
date = to_date
while date >= from_date
  parse = if options[:proof]
            labmda { |a, b, c| parser.parse_date_house_only_in_proof a, b, c }
          else
            ->(a, b, c) { parser.parse_date_house a, b, c }
          end
  parse_with_retry options[:interactive], parse, date, "#{conf.xml_path}/scrapedxml/representatives_debates/#{date}.xml", House.representatives
  progress.inc

  parse_with_retry options[:interactive], parse, date, "#{conf.xml_path}/scrapedxml/senate_debates/#{date}.xml", House.senate
  progress.inc
  date = date - 1
end

progress.finish

# And load up the database
if options[:load_database]
  command_options = " --from=#{from_date} --to=#{to_date}"
  command_options << " --debates"
  command_options << " --lordsdebates"
  command_options << " --force" if options[:force]

  # Starts with 'perl' to be friendly with Windows
  system("perl #{conf.web_root}/twfy/scripts/xml2db.pl #{command_options}")
end

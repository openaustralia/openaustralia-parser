#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"
require "optparse"

require_relative "lib/people"
require_relative "lib/hansard_parser"
require_relative "lib/configuration"

# Refreshes the days whose cached APH XML is still at proof stage, up to a limit. It starts at a day 12 months ago and
# works outward, alternating between the next newer and the next older day, so each run reaches toward today and toward
# the past together.
# Each day goes through the same refresh as parse-speeches.rb --proof (HansardParser#parse_date_house_only_in_proof),
# then the changed days are loaded into the database.
#
# With --unknown it works on the days we cannot yet say are proof or final instead: those whose scrapedxml has no
# proof attribute. A day whose cached copy is final is parsed again from the cache, without calling APH; a day
# whose cached copy is proof is refreshed from APH as above. Either way the day gets its attribute, so it drops out
# of the list and a daily run works through the backlog.
class RefreshProofDays
  DEFAULT_LIMIT = 100

  def initialize(args)
    @args = args
  end

  def run
    options = { limit: DEFAULT_LIMIT, load_database: true, unknown: false, around: Date.today << 12 }

    OptionParser.new do |opts|
      opts.banner = "Usage: refresh-proof-days.rb [options]"
      opts.on("--limit=N", Integer, "Refresh at most N days, counting each house's day as one (default #{DEFAULT_LIMIT})") do |n|
        options[:limit] = n
      end
      opts.on("--unknown", "Work on days with no proof attribute in scrapedxml: re-parse final ones from the cache, refresh proof ones") do |unknown|
        options[:unknown] = unknown
      end
      opts.on("--around=DATE", "Start from DATE and work outward, alternating newer and older days (default 12 months ago)") do |date|
        options[:around] = Date.parse(date)
      end
      opts.on("--[no-]load", "Load the refreshed days into the database (default), or only generate XML") do |load|
        options[:load_database] = load
      end
      opts.on("--output-dir=PATH", "Use PATH instead of conf.xml_path") do |path|
        options[:output_dir] = path
      end
    end.parse!(@args)

    conf = Configuration.new
    output_dir = options[:output_dir] || conf.xml_path
    scraped_root = "#{output_dir}/scrapedxml"
    %w[representatives_debates senate_debates].each do |directory|
      FileUtils.mkdir_p "#{scraped_root}/#{directory}"
    end

    parser = HansardParser.new(PeopleCSVReader.read_members, output_dir: output_dir)
    days = if options[:unknown]
             parser.days_without_proof_flag(limit: options[:limit], around: options[:around])
           else
             parser.proof_days(limit: options[:limit], around: options[:around])
           end
    puts "Working on #{days.size} days"

    refreshed = []
    failed = []
    blocked = false
    days.each do |date, house|
      path = "#{scraped_root}/#{parser.house_directory_name(house)}/#{date}.xml"
      if parser.cached_proof(date, house) == false
        # Final already, so there is nothing to ask APH for
        parser.parse_date_house(date, path, house)
      else
        parser.parse_date_house_only_in_proof(date, path, house)
      end
      if parser.aph_blocked?
        # Asking again now would only make it worse, so leave this day and the rest for the next run
        blocked = true
        break
      end
      refreshed << date
    rescue StandardError => e
      # One bad day must not stop the rest of the batch
      puts "ERROR While processing #{house.name} #{date}: #{e.message}"
      failed << [date, house]
    end

    load_days(conf, refreshed.uniq.sort, options[:load_database])

    puts "aph.gov.au is refusing requests (403 or 429), so stopping. The days not yet done will be tried again next run." if blocked
    puts "Refreshed #{refreshed.size} of #{days.size} days, #{failed.size} failed"
    exit 1 if failed.any?
  end

  private

  # Loaded one date at a time, as xml2db.pl would otherwise reload every day between the first and last.
  def load_days(conf, dates, load_database)
    dates.each do |date|
      # Starts with 'perl' to be friendly with Windows, as in parse-speeches.rb
      command = "#{conf.web_root}/twfy/bin/run scripts/xml2db.pl --from=#{date} --to=#{date} --debates --senatedebates"
      if load_database
        system(command)
      else
        puts "No-load option has disabled: #{command}"
      end
    end
  end
end

Configuration.report_errors { RefreshProofDays.new(ARGV).run } if File.expand_path($PROGRAM_NAME) == File.expand_path(__FILE__)

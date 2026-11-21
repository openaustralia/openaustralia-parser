#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"

require "date"
require "fileutils"
require "net/http"
require "nokogiri"
require "optparse"
require "time"
require "uri"

# Copies the days of Hansard that production has cached from APH (https://data.openaustralia.org.au/origxml/) into the
# local origxml cache, so a development checkout can parse real days without asking APH for them.
# It only fetches a day that is missing locally or newer on the server, using If-Modified-Since with the local file's
# modification time, and gives each file the server's Last-Modified time. A file that is newer locally, for example one
# refreshed from APH, is left alone. A development tool: nothing runs it on a schedule.
class PullOrigxml
  BASE_URL = "https://data.openaustralia.org.au"
  DEFAULT_OUTPUT_DIR = File.expand_path("tmp/pwdata", __dir__)
  USER_AGENT = "openaustralia-parser pull-origxml.rb (copying the public origxml for development)"
  HOUSES = { "representatives" => "representatives_debates", "senate" => "senate_debates" }.freeze

  def initialize(args, stdout: $stdout)
    @args = args
    @stdout = stdout
    @counts = Hash.new(0)
  end

  def run
    options = parse_options
    houses = options[:house] ? [options[:house]] : HOUSES.keys

    Net::HTTP.start(base.host, base.port, use_ssl: base.scheme == "https") do |http|
      @http = http
      houses.each do |house|
        pull_house(HOUSES.fetch(house), options)
        break if @stopped
      end
    end

    @stdout.puts "The server asked us to slow down, so stopping. Run again later to carry on." if @stopped
    @stdout.puts "Downloaded #{@counts[:downloaded]}, up to date #{@counts[:up_to_date]}, failed #{@counts[:failed]}"
    exit 1 if @counts[:failed].positive?
  end

  private

  def parse_options
    options = { to: Date.today, output_dir: DEFAULT_OUTPUT_DIR, delay: 0.5, base_url: BASE_URL }

    OptionParser.new do |opts|
      opts.banner = "Usage: pull-origxml.rb --from=DATE [options]"
      opts.on("--from=DATE", "First day to pull (required, so a run never copies the whole archive by accident)") do |date|
        options[:from] = Date.parse(date)
      end
      opts.on("--to=DATE", "Last day to pull (default today)") { |date| options[:to] = Date.parse(date) }
      opts.on("--house=HOUSE", HOUSES.keys, "representatives or senate (default both)") { |house| options[:house] = house }
      opts.on("--force", "Download even if the local file is as new or newer") { options[:force] = true }
      opts.on("--dry-run", "List the days the server has and whether each is present locally, without downloading") do
        options[:dry_run] = true
      end
      opts.on("--delay=SECONDS", Float, "Wait between requests (default #{options[:delay]})") { |seconds| options[:delay] = seconds }
      opts.on("--output-dir=PATH", "Use PATH instead of tmp/pwdata under this repository") { |path| options[:output_dir] = path }
      opts.on("--base-url=URL", "Pull from URL instead of #{BASE_URL}") { |url| options[:base_url] = url }
    end.parse!(@args)

    abort "--from=DATE is required" unless options[:from]
    @base = URI(options[:base_url])
    options
  end

  attr_reader :base

  def pull_house(directory, options)
    dates = days_on_server(directory, options)
    @stdout.puts "#{directory}: #{dates.size} days on the server from #{options[:from]} to #{options[:to]}"

    dates.each do |date|
      path = local_path(options[:output_dir], directory, date)
      if options[:dry_run]
        @stdout.puts "#{date} #{File.exist?(path) ? 'present locally' : 'not present locally'}"
        next
      end

      pull_day(directory, date, path, options)
      break if @stopped

      sleep options[:delay]
    end
  end

  def days_on_server(directory, options)
    response = get("/origxml/#{directory}/")
    abort "Could not list #{directory} on the server (#{response.code})" unless response.is_a?(Net::HTTPSuccess)

    response.body.scan(/href="(\d{4}-\d{2}-\d{2})\.xml"/).flatten.map { |text| Date.iso8601(text) }
            .grep(options[:from]..options[:to]).sort
  end

  def pull_day(directory, date, path, options)
    headers = {}
    headers["If-Modified-Since"] = File.mtime(path).httpdate if File.exist?(path) && !options[:force]
    response = get("/origxml/#{directory}/#{date}.xml", headers)

    case response
    when Net::HTTPNotModified
      count(:up_to_date, "#{date} #{directory}: up to date")
    when Net::HTTPSuccess
      problem = problem_with(response.body, date)
      return count(:failed, "#{date} #{directory}: not saved, #{problem}") if problem

      save(path, response.body, response["Last-Modified"])
      count(:downloaded, "#{date} #{directory}: downloaded")
    when Net::HTTPTooManyRequests, Net::HTTPServiceUnavailable
      @stopped = true
    else
      count(:failed, "#{date} #{directory}: the server answered #{response.code}")
    end
  end

  def get(path, headers = {})
    @http.get(path, { "User-Agent" => USER_AGENT }.merge(headers))
  end

  def local_path(output_dir, directory, date)
    File.join(output_dir, "origxml", directory, "#{date}.xml")
  end

  def problem_with(text, date)
    root = Nokogiri::XML(text).root
    return "it is not a hansard document" unless root&.name == "hansard"

    found = root.at_xpath("session.header/date")&.text&.strip
    "it is for #{found}, not #{date}" if found && found != date.to_s
  end

  # Written to a temporary file first, so an interrupted run never leaves half a day where the parser would read it.
  def save(path, body, last_modified)
    FileUtils.mkdir_p(File.dirname(path))
    temporary = "#{path}.new"
    File.binwrite(temporary, body)
    modified = last_modified ? Time.httpdate(last_modified) : Time.now
    File.utime(modified, modified, temporary)
    File.rename(temporary, path)
  ensure
    FileUtils.rm_f(temporary) if temporary
  end

  def count(kind, message)
    @counts[kind] += 1
    @stdout.puts message
  end
end

PullOrigxml.new(ARGV).run if File.expand_path($PROGRAM_NAME) == File.expand_path(__FILE__)

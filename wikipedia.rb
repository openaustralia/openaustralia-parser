#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"

# Figures out the URLs for the Wikipedia biography pages of Representatives and Senators

require "logger"

require "active_support"
require "active_record"
require "fileutils"
require "mechanize"
require "optparse"

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"

require "configuration"
require "extract_wikipedia_links"
require "name"
require "people"

class WikipediaScript
  def initialize(args)
    @args = args
    @options = { load_database: true, output_dir: nil }
    OptionParser.new do |opts|
      opts.banner = "Usage: wikipedia.rb [--no-load] [--output-dir=PATH]"
      opts.on("--no-load", "Skip calling mpinfoin.pl at the end") do
        @options[:load_database] = false
      end
      opts.on("--output-dir=PATH", "Write XML output to PATH instead of conf.members_xml_path") do |path|
        @options[:output_dir] = path
      end
    end.parse!(@args)
  end

  def write_links(links, filename)
    xml = File.open(filename, "w")
    x = Builder::XmlMarkup.new(target: xml, indent: 1)
    x.instruct!
    x.peopleinfo do
      links.each { |link| x.personinfo(id: link[0], wikipedia_url: link[1]) }
    end
    xml.close
  end

  def run
    conf = Configuration.new

    output_dir = @options[:output_dir] || conf.members_xml_path
    FileUtils.mkdir_p output_dir

    puts "Reading member data..."
    people = PeopleCSVReader.read_members

    agent = Mechanize.new

    # Slightly naughty because Wikipedia specifically blocks Ruby Mechanize
    agent.user_agent_alias = "Mac Safari"

    puts "Extracting all Wikipedia links for Representatives..."
    links = extract_all_representative_wikipedia_links(people, agent)

    raise "Unable to extract Wikipedia links for Representatives!" if links.nil? || links.empty?

    puts "Writing Wikipedia links for Representatives to: #{output_dir}/wikipedia-commons.xml"
    write_links(links, "#{output_dir}/wikipedia-commons.xml")

    # For Representatives, just for curiosity’s sake, find out which has a link back to OpenAustralia
    puts "Checking Representatives to see if they have a link back to OpenAustralia..."
    links.each { |link| check_wikipedia_page(link[1], agent) }

    puts "Writing Wikipedia links for Senators to: #{output_dir}/wikipedia-commons.xml"
    write_links(extract_all_senator_wikipedia_links(people, agent),
                "#{output_dir}/wikipedia-lords.xml")

    if @options[:load_database]
      system("#{conf.web_root}/twfy/scripts/mpinfoin.pl links")
    else
      puts "No-load option has disabled the following that is normally run:"
      puts "  #{conf.web_root}/twfy/scripts/mpinfoin.pl links"
    end
    0
  end
end

exit WikipediaScript.new(ARGV).run.to_i if $PROGRAM_NAME == __FILE__

#!/usr/bin/env ruby
# frozen_string_literal: true

require "configuration"

require "sitemap_generator/comment"
require "sitemap_generator/counted_file"
require "sitemap_generator/hansard"
require "sitemap_generator/member"
require "sitemap_generator/news"
require "sitemap_generator/sitemap"
require "sitemap_generator/sitemap_url"

# Generate sitemap.xml for quick and easy search engine updating
# This is run as part of twfy/scripts/morningupdate
class SitemapGenerator
  attr_reader :base_dir

  def initialize(args)
    @args = args
    @options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: sitemap.rb [--output-dir=PATH]"
      opts.on("--output-dir=PATH", "Write postcodes.csv to this dir instead of data/") do |path|
        @options[:output_dir] = path
      end
    end.parse!(@args)
  end

  def show_process(index)
    print "." if (index % 100).zero?
    puts if index % 10_000 == 9999
  end

  def run
    conf = Configuration.new

    output_dir = @options[:output_dir] || conf.base_dir

    # Establish the connection to the database
    ActiveRecord::Base.establish_connection(
      adapter: "mysql2",
      host: conf.database_host,
      username: conf.database_user,
      password: conf.database_password,
      database: conf.database_name
    )

    s = Sitemap.new(conf.website, output_dir, conf.web_path)

    # Arrange some static URL's with the most quickly changing at the top

    puts "\nAdding some static URLs with dynamic content..."
    s.add_url "/", changefreq: :hourly,
              lastmod: [Comment.last_modified, Hansard.last_modified, News.last_modified].compact.max
    s.add_url "/comments/recent/", changefreq: :hourly, lastmod: Comment.last_modified
    s.add_url "/debates/", changefreq: :daily,
              lastmod: Hansard.most_recent_in_house("reps").last_modified
    s.add_url "/hansard/", changefreq: :daily, lastmod: Hansard.most_recent.last_modified
    s.add_url "/senate/", changefreq: :daily,
              lastmod: Hansard.most_recent_in_house("senate").last_modified
    s.add_url "/news/", changefreq: :weekly, lastmod: News.most_recent&.last_modified
    s.add_url "/mps/", changefreq: :monthly
    s.add_url "/senators/", changefreq: :monthly

    puts "\nAdding some static URLs with no dynamic content..."
    s.add_url "/about/", changefreq: :monthly
    s.add_url "/contact/", changefreq: :monthly
    s.add_url "/help/", changefreq: :monthly
    s.add_url "/houserules/", changefreq: :monthly
    # The find out about your representative page
    s.add_url "/mp/", changefreq: :monthly
    s.add_url "/privacy/", changefreq: :monthly
    # Help with Searching
    s.add_url "/search/", changefreq: :monthly
    s.add_url "/alert/", changefreq: :monthly

    # Not going to include the glossary until we actually start to use it
    # urls << "/glossary/"
    # No point in including yearly overview of days in which speeches occur because there's nothing on
    # the page to search on

    puts "\nAdding all the Hansard urls (for both House of Representatives and the Senate)..."
    puts "[Outputs dot (.) every 100 records, a line is 10,000 records]"
    Hansard.find_each.with_index do |h, index|
      show_process(index)
      # Skip section urls that just would get redirected to subsection urls
      unless h.section? && h.speeches.size == 1
        # Saying the Hansard could change monthly because of reparsing
        s.add_url h.url, changefreq: :monthly, lastmod: h.last_modified_including_comments
      end
    end

    %w[reps senate].each do |house|
      puts "\nAdding URLs for daily highlights of speeches in #{house}..."
      Hansard.find_all_dates_for_house(house).each_with_index do |hdate, index|
        show_process(index)
        s.add_url Hansard.url_for_date(hdate, house),
                  changefreq: :monthly,
                  lastmod: Hansard.find_all_sections_by_date_and_house(hdate,
                                                                       house).map(&:last_modified).compact.max
      end
    end

    puts "\nAdding member pages ..."
    Member.find_all_person_ids.each_with_index do |person_id, index|
      show_process(index)
      # Could change daily because of recent speeches they make
      s.add_url Member.find_most_recent_by_person_id(person_id).url, changefreq: :daily
    end

    puts "\nAdding the news items..."
    News.find_all.each_with_index do |n, index|
      show_process(index)
      s.add_url n.url, changefreq: :monthly, lastmod: n.last_modified
    end

    puts "\nFinishing up the sitemap generation..."
    s.finish
    puts "\nDone! sitemap generated under #{output_dir}"
  end
end

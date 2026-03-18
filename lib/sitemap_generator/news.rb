# A news item
class SitemapGenerator
  class News
    def initialize(title, date)
      @title = title
      @date = date
    end

    def last_modified
      Time.parse(@date)
    end

    # The most recently added news item
    def self.most_recent
      # Loads all news items into memory but should be okay because there are not many
      find_all.max { |a, b| a.last_modified <=> b.last_modified }
    end

    def self.find_all
      news = []
      return news if ENV["EXCLUDE_NEWS"]

      MySociety::Config.fork_php do |child|
        child.print('<?php require "../twfy/www/docs/news/editme.php"; foreach ($all_news as $k => $v) { print $v[0]."\n"; print $v[2]."\n"; } ?>')
        child.close_write
        child.readlines.map(&:strip).each_slice(2) do |title, date|
          news << News.new(title, date)
        end
      end
      news
    end

    def self.last_modified
      News.most_recent&.last_modified
    end

    def url
      "/news/archives/#{url_encoded_date}/#{url_encoded_title}"
    end

    def url_encoded_title
      @title.downcase.gsub(/[^a-z0-9 ]/, "").tr(" ", "_")[0..15]
    end

    def url_encoded_date
      @date[0..9].tr("-", "/")
    end
  end
end

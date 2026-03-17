class SitemapGenerator
  class Comment < ActiveRecord::Base
    # The most recently added comment
    def self.most_recent
      Comment.order("posted DESC").first
    end

    def self.last_modified
      Comment.most_recent&.last_modified
    end

    def last_modified
      posted
    end
  end
end

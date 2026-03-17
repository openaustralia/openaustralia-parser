class SitemapGenerator
  class SitemapUrl
    attr_reader :loc, :changefreq, :lastmod

    CHANGEFREQ_VALUES = %w[always hourly daily weekly monthly yearly never].freeze

    def initialize(loc, options)
      @loc = loc
      @changefreq = options.delete(:changefreq)
      @changefreq = @changefreq.to_s if @changefreq
      @lastmod = options.delete(:lastmod)
      unless @changefreq.nil? || CHANGEFREQ_VALUES.include?(@changefreq)
        throw "Invalid value #{@changefreq} for changefreq"
      end
      throw "Invalid options in add_url" unless options.empty?
    end
  end
end

# Currently a section can be either a speech or a division
class Section
  attr_accessor :time, :url
  
  def initialize(time, url, count, date, house, logger = nil)
    @time, @url, @count, @date, @house, @logger = time, url, count, date, house, logger
  end

  # Quoting of url's is required to be nice and standards compliant
  def quoted_url
    @url.gsub('&', '&amp;')
  end
  
  def id
    debate_name = case @house
    when House.representatives
      "debate"
    else
      "lords"
    end
    "uk.org.publicwhip/#{debate_name}/#{@date}.#{@count}"
  end
end

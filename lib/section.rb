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
    if @house.representatives?
      "uk.org.publicwhip/debate/#{@date}.#{@count}"
    else
      "uk.org.publicwhip/lords/#{@date}.#{@count}"
    end
  end
end

# frozen_string_literal: true

# Currently a section can be either a speech or a division
class Section
  attr_accessor :time, :url

  def initialize(time, url, count, date, house, logger = nil)
    @time, @url, @count, @date, @house, @logger = time, url, count, date, house, logger
  end

  # Quoting of url's is required to be nice and standards compliant
  def quoted_url
    @url.gsub("&", "&amp;")
  end

  def id
    if @house.representatives?
      "uk.org.publicwhip/debate/#{@date}.#{@count}"
    else
      "uk.org.publicwhip/lords/#{@date}.#{@count}"
    end
  end

  def to_time(alternate_time = nil)
    time = (alternate_time || @time).split(":").map(&:to_i)
    hour = time[0]
    minutes = time[1]
    # puts "Time.local(#{@date.year}, #{@date.month}, #{@date.day}, #{hour}, #{minutes})"
    # Handle situation where hours are >= 24. If that happens shift it to the next day
    if hour && hour >= 24
      Time.local(@date.year, @date.month, @date.day, hour - 24, minutes) + 24 * 60 * 60
    else
      Time.local(@date.year, @date.month, @date.day, hour, minutes)
    end
  end
end

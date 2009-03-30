require 'section'

class Division < Section
  def initialize(time, url, major_count, minor_count, date, house, logger = nil)
    super(time, url, major_count, minor_count, date, house, logger)
  end
end
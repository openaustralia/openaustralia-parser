require 'section'

class Division < Section
  def initialize(date, major_count, minor_count, house)
    @date, @major_count, @minor_count, @house = date, major_count, minor_count, house
  end
end
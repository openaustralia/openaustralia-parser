require 'house_period'

class Person
  attr_reader :house_periods, :id
  
  def Person.reset_id_counter
    @@id = 10001
  end
  
  reset_id_counter
  
  def initialize(override_id = nil)
    @house_periods = []
    if override_id
      @id = override_id
    else
      @id = @@id
      @@id = @@id + 1
    end
  end
  
  # Returns the house period which is the latest in time
  def latest_house_period
    @house_periods.sort {|a, b| a.to_date <=> b.to_date}.last
  end
  
  def latest_name
    latest_house_period.name
  end
  
  def add_period(params)
    @house_periods << Period.new(params.merge(:person => self))
  end
  
  # Adds a single continuous period when this person was in the house of representatives
  # Note that there might be several of these per person
  def add_house_period(params)
    add_period(params.merge(:house => "representatives"))
  end
  
  # Returns true if this person has a house_period with the given id
  def has_house_period_with_id?(id)
    !find_house_period_by_id(id).nil?
  end
  
  def find_house_period_by_id(id)
    @house_periods.find{|p| p.id == id}
  end
  
  def ==(p)
    id == p.id && house_periods == p.house_periods
  end
end

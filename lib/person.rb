require 'house_period'

class Person
  attr_reader :name, :id, :house_periods
  
  @@id = 10001
  
  def initialize(name)
    @name = name
    @house_periods = []
    @id = @@id
    @@id = @@id + 1
  end
  
  # Adds a single continuous period when this person was in the house of representatives
  # Note that there might be several of these per person
  def add_house_period(params)
    @house_periods << HousePeriod.new(params)
  end
  
  def display
    puts "Member: #{@name.informal_name}"
    @house_periods.each do |p|
      puts "  start: #{p.from_date} #{p.from_why}, end: #{p.to_date} #{p.to_why}"    
    end    
  end
end

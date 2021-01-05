require "period"
require "house"

class Person
  attr_reader :periods, :person_count, :name, :alternate_names, :minister_positions, :birthday, :aph_id

  def id
    "uk.org.publicwhip/person/#{id_count}"
  end

  def id_count
    10000 + @person_count
  end

  def initialize(params)
    @name = params.delete(:name)
    @alternate_names = params.delete(:alternate_names) || []
    @person_count = params.delete(:count)
    @birthday = params.delete(:birthday)
    @aph_id = params.delete(:aph_id)
    raise "Invalid keys: #{params.keys}" unless params.empty?
    raise ":name and :count are required parameters" unless @name && @person_count

    @periods = []
    @minister_positions = []
  end

  def all_names
    [name] + alternate_names
  end

  def name_matches?(a)
    all_names.any? { |n| n.matches?(a) }
  end

  # Does this person have current senate/house of representatives positions on the given date
  def current_position_on_date?(date)
    @periods.detect { |p| p.current_on_date?(date) }
  end

  def position_current_on_date(date, house)
    @periods.find { |p| p.house == house && p.current_on_date?(date) }
  end

  def house_periods
    @periods.find_all(&:representative?)
  end

  def senate_periods
    @periods.find_all(&:senator?)
  end

  def add_period(params)
    @periods << Period.new(params.merge(person: self))
  end

  def add_minister_position(params)
    @minister_positions << MinisterPosition.new(params.merge(person: self))
  end

  def ==(other)
    id == other.id && periods == other.periods
  end
end

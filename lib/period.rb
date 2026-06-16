# frozen_string_literal: true

class PeriodBase
  attr_accessor :from_date, :to_date, :person

  def initialize(params)
    @from_date =  params.delete(:from_date)
    @to_date =    params.delete(:to_date)
    @person =     params.delete(:person)
    raise "Invalid keys: #{params.keys}" unless params.empty?
  end

  def current_on_date?(date)
    date >= @from_date && date <= @to_date
  end

  def current?
    current_on_date?(Date.today)
  end

  def name
    person.name
  end
end

class MinisterPosition < PeriodBase
  attr_accessor :position, :position_count

  def id
    "uk.org.publicwhip/moffice/#{@position_count}"
  end

  def initialize(params)
    @position = params.delete(:position)
    @position_count = params.delete(:count)
    raise ":position and :count are required parameters" unless @position && @position_count

    super
  end
end

# Represents a continuous period of service in either the House of Representatives or the Senate
# for a specific party and division.
# The reason for starting and ending may vary (e.g. election, defeat, resignation).
class Period < PeriodBase
  attr_accessor :from_why, :to_why, :division, :state, :party, :house
  attr_reader :count

  # returns a unique identifier based on person and house (but NOT which period!)
  def id
    if senator?
      "uk.org.publicwhip/lord/#{100000 + @count}"
    else
      "uk.org.publicwhip/member/#{@count}"
    end
  end

  def representative?
    @house.representatives?
  end

  def senator?
    @house.senate?
  end

  def initialize(params)
    # TODO: Make some parameters compulsory and others optional
    unless params[:person] && params[:count]
      raise ":person and :count parameter required in Period.new"
    end

    @from_why =   params.delete(:from_why)
    @to_why =     params.delete(:to_why)
    @division =   params.delete(:division)
    @state =      params.delete(:state)
    @party =      params.delete(:party)
    @house =      params.delete(:house)
    raise ":house parameter not valid" unless representative? || senator?

    @count =      params.delete(:count)
    super
  end

  def house_speaker?
    representative? && @party == "SPK"
  end

  def deputy_house_speaker?
    representative? && @party == "CWM"
  end

  def senate_president?
    senator? && @party == "PRES"
  end

  def deputy_senate_president?
    senator? && @party == "DPRES"
  end

  def ==(other)
    other.is_a?(Period) && id == other.id && from_date == other.from_date && to_date == other.to_date &&
      from_why == other.from_why && to_why == other.to_why && division == other.division && state == other.state && party == other.party && house == other.house
  end
end

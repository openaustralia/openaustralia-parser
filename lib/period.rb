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
  attr_accessor :position, :minister_count

  def self.reset_id_counter
    @@next_minister_count = 1
  end

  reset_id_counter

  def id
    "uk.org.publicwhip/moffice/#{@minister_count}"
  end

  def initialize(params)
    @position = params.delete(:position)
    if params[:count]
      @minister_count = params.delete(:count)
    else
      @minister_count = @@next_minister_count
    end
    @@next_minister_count = @@next_minister_count + 1
    super
  end
end

# Represents a period in the house of representatives or the senate
class Period < PeriodBase
  attr_accessor :from_why, :to_why, :division, :state, :party, :house
  attr_reader :count

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
    # TODO: Make some parameters compulsary and others optional
    raise ":person and :count parameter required in Period.new" unless params[:person] && params[:count]

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

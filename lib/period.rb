require 'id'

class PeriodBase
  attr_accessor :from_date, :to_date, :person
  
  def initialize(params)
    @from_date =  params[:from_date]
    @to_date =    params[:to_date]
    @person =     params.delete(:person)
    invalid_keys = params.keys - [:from_date, :to_date, :person]
    throw "Invalid keys: #{invalid_keys}" unless invalid_keys.empty?
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
  
  def MinisterPosition.reset_id_counter
    @@next_minister_count = 1
  end
  
  reset_id_counter
  
  def id
    "uk.org.publicwhip/moffice/#{@minister_count}"
  end
  
  def initialize(params)
    @position = params.delete(:position)
    @minister_count = @@next_minister_count
    @@next_minister_count = @@next_minister_count + 1
    super
  end  
end

# Represents a period in the house of representatives
class Period < PeriodBase
  attr_accessor :from_why, :to_why, :division, :party, :house
  attr_reader :id
  
  def Period.reset_id_counter
    @@rep_id = Id.new("uk.org.publicwhip/member/")
    @@senator_id = Id.new("uk.org.publicwhip/lord/")
  end
  
  reset_id_counter
  
  def initialize(params)
    # TODO: Make some parameters compulsary and others optional
    throw ":person parameter required in HousePeriod.new" unless params[:person]
    @from_why =   params.delete(:from_why)
    @to_why =     params.delete(:to_why)
    @division =   params.delete(:division)
    @party =      params.delete(:party)
    @house =      params.delete(:house)
    if @house != "representatives" && @house != "senate"
      throw ":house parameter must have value 'representatives' or 'senate'"
    end
    if params[:id]
      @id = params.delete(:id)
    else
      if @house == "senate"
        @id = @@senator_id.clone
        @@senator_id.next
      else
        @id = @@rep_id.clone
        @@rep_id.next
      end
    end
    super
  end
  
  def house_speaker?
    @house == "representatives" && @party == "SPK"
  end
  
  def deputy_house_speaker?
    @house == 'representatives' && @party == "CWM"
  end
  
  def ==(p)
    id.to_s == p.id.to_s && from_date == p.from_date && to_date == p.to_date &&
      from_why == p.from_why && to_why == p.to_why && division == p.division && party == p.party
  end
end

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
end

class MinisterPosition < PeriodBase
  attr_accessor :position
  
  def initialize(params)
    @position = params.delete(:position)
    super
  end
end

# Represents a period in the house of representatives
class Period < PeriodBase
  attr_accessor :from_why, :to_why, :division, :party, :house
  attr_reader :id
  
  def Period.reset_id_counter
    @@id = Id.new("uk.org.publicwhip/member/")
  end
  
  reset_id_counter
  
  def initialize(params)
    # TODO: Make some parameters compulsary and others optional
    throw ":person parameter required in HousePeriod.new" unless params[:person]
    if params[:id]
      @id = params.delete(:id)
    else
      @id = @@id.to_s
      @@id.next
    end
    @from_why =   params.delete(:from_why)
    @to_why =     params.delete(:to_why)
    @division =   params.delete(:division)
    @party =      params.delete(:party)
    @house =      params.delete(:house)
    if @house != "representatives" && @house != "senate"
      throw ":house parameter must have value 'representatives' or 'senate'"
    end
    super
  end
  
  def ==(p)
    id == p.id && from_date == p.from_date && to_date == p.to_date &&
      from_why == p.from_why && to_why == p.to_why && division == p.division && party == p.party
  end
  
  def current?
    @to_why == "current_member"
  end
end

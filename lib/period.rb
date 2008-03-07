# Represents a period in the house of representatives
class Period
  attr_accessor :from_date, :to_date, :from_why, :to_why, :division, :party, :person, :name, :house
  attr_reader :id
  
  def Period.reset_id_counter
    @@id = 1
  end
  
  reset_id_counter
  
  def initialize(params)
    # TODO: Make some parameters compulsary and others optional
    throw ":name parameter required in HousePeriod.new" unless params[:name]
    throw ":person parameter required in HousePeriod.new" unless params[:person]
    if params[:id]
      @id = params[:id]
    else
      @id = @@id
      @@id = @@id + 1
    end
    @from_date =  params[:from_date]
    @to_date =    params[:to_date]
    @from_why =   params[:from_why]
    @to_why =     params[:to_why]
    @division =   params[:division]
    @party =      params[:party]
    @person =     params[:person]
    @name =       params[:name]
    @house =      params[:house]
    if @house != "representatives" && @house != "senate"
      throw ":house parameter must have value 'representatives' or 'senate'"
    end
    throw "Invalid keys" unless (params.keys -
      [:id, :house, :division, :party, :from_date,
      :to_date, :from_why, :to_why, :person, :name]).empty?
  end
  
  def ==(p)
    id == p.id && from_date == p.from_date && to_date == p.to_date &&
      from_why == p.from_why && to_why == p.to_why && division == p.division && party == p.party
  end
  
  def current?
    @to_why == "current_member"
  end
end

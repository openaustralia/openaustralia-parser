# Represents a period in the house of representatives
class HousePeriod
  attr_accessor :from_date, :to_date, :from_why, :to_why, :division, :party
  attr_reader :id
  
  @@id = 1
  
  def initialize(params)
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
    throw "Invalid keys" unless (params.keys -
      [:id, :division, :party, :from_date,
      :to_date, :from_why, :to_why]).empty?
  end
  
  def ==(p)
    id == p.id && from_date == p.from_date && to_date == p.to_date &&
      from_why == p.from_why && to_why == p.to_why && division == p.division && party == p.party
  end
  
  def current?
    @to_why == "current_member"
  end
end

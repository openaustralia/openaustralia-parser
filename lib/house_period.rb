# Represents a period in the house of representatives
class HousePeriod
  attr_reader :from_date, :to_date, :from_why, :to_why
  attr_reader :division, :party, :id
  
  @@id = 1
  
  def initialize(params)
    @id = @@id
    @@id = @@id + 1
    @from_date =  params[:from_date]
    @to_date =    params[:to_date]
    @from_why =   params[:from_why]
    @to_why =     params[:to_why]
    @division =   params[:division]
    @party =      params[:party]
    throw "Invalid keys" unless (params.keys -
      [:division, :party, :from_date,
      :to_date, :from_why, :to_why]).empty?
  end
  
  def current?
    @to_why == "current_member"
  end
end

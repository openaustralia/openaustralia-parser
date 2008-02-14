# Represents a period in the house of representatives
class HousePeriod
  attr_reader :from_date, :to_date, :from_why, :to_why
  attr_reader :division, :party, :name, :id
  
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
    @name  =      params[:name]
    throw "Invalid keys" unless (params.keys -
      [:division, :party, :name, :from_date,
      :to_date, :from_why, :to_why]).empty?
  end
  
  def current?
    @to_why == "current_member"
  end
  
  def output(x)
    x.member(:id => "uk.org.publicwhip/member/#{@id}",
      :house => "commons", :title => @name.title, :firstname => @name.first,
      :lastname => @name.last, :constituency => @division, :party => @party,
      :fromdate => @from_date, :todate => @to_date, :fromwhy => @from_why, :towhy => @to_why)
  end
end

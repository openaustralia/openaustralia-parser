class Member
  attr_reader :id_member, :id_person, :house, :title, :firstname, :lastname, :constituency, :party, :fromdate,
    :todate, :fromwhy, :towhy

  def initialize(params)
    @id_member =    params[:id_member]
    @id_person =    params[:id_person]
    @house =        params[:house]
    @title =        params[:title]
    @firstname =    params[:firstname]
    @lastname =     params[:lastname]
    @constituency = params[:constituency]
    @party =        params[:party]
    @fromdate =     params[:fromdate]
    @todate =       params[:todate]
    @fromwhy =      params[:fromwhy]
    @towhy =        params[:towhy]
    throw "Invalid keys" unless (params.keys -
      [:id_member, :id_person, :house, :title, :firstname, :lastname, :constituency, :party, :fromdate,
      :todate, :fromwhy, :towhy]).empty?
  end
  
  def output_member(x)
    x.member(:id => "uk.org.publicwhip/member/#{@id_member}",
      :house => @house, :title => @title, :firstname => @firstname,
      :lastname => @lastname, :constituency => @constituency, :party => @party,
      :fromdate => @fromdate, :todate => @todate, :fromwhy => @fromwhy, :towhy => @towhy)
  end
  
  def output_person(x)
    x.person(:id => "uk.org.publicwhip/person/#{@id_person}", :latestname => "#{@firstname} #{@lastname}") do
      x.office(:id => "uk.org.publicwhip/member/#{@id_member}", :current => "yes")
    end
  end
end


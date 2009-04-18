require 'section'

class Division < Section
  def initialize(yes, no, yes_tellers, no_tellers, time, url, count, division_count, date, house, logger = nil)
    @yes, @no, @yes_tellers, @no_tellers, @division_count = yes, no, yes_tellers, no_tellers, division_count
    super(time, url, count, date, house, logger)
  end
  
  def output(x)
    x.division(:id => id, :nospeaker => "true", :divdate => @date, :divnumber => @division_count, :time => @time, :url => quoted_url) do
      
      if @house.representatives?
        x.divisioncount(:ayes => @yes.size, :noes => @no.size,
          :tellerayes => @yes_tellers.size, :tellernoes => @no_tellers.size)
          yes_term = "aye"
          no_term = "no"
      else
        x.divisioncount(:content => @yes.size, "not-content" => @no.size)
        yes_term = "content"
        no_term = "not-content"
      end
      output_vote_list(x, @yes, @yes_tellers, yes_term)
      output_vote_list(x, @no, @no_tellers, no_term)
    end
  end
  
  private

  def output_vote_list(x, members, tellers, vote)
    if @house.representatives?
      mp_tag = "mpname"
      mps_tag = "mplist"
    else
      mp_tag = "lord"
      mps_tag = "lordlist"
    end
    x.tag!(mps_tag, :vote => vote) do
      members.each do |m|
        if tellers.include?(m)
          x.tag!(mp_tag, {:id => m.id, :vote => vote, :teller => "yes"}, m.name.full_name)
        else
          x.tag!(mp_tag, {:id => m.id, :vote => vote}, m.name.full_name)
        end
      end
    end
  end
    
end
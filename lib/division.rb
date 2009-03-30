require 'section'

class Division < Section
  def initialize(yes, no, yes_tellers, no_tellers, time, url, major_count, minor_count, date, house, logger = nil)
    @yes, @no, @yes_tellers, @no_tellers = yes, no, yes_tellers, no_tellers
    super(time, url, major_count, minor_count, date, house, logger)
  end
  
  def output(x)
    x.division(:id => id, :nospeaker => "true", :divdate => @date, :time => @time, :url => quoted_url) do
      x.divisioncount(:ayes => @yes.size, :noes => @no.size, :tellerayes => @yes_tellers.size, :tellernoes => @no_tellers.size)
      output_vote_list(x, @yes, @yes_tellers, "aye")
      output_vote_list(x, @no, @no_tellers, "no")
    end
  end
  
  private

  def output_vote_list(x, members, tellers, vote)
    x.mplist(:vote => vote) do
      members.each do |m|
        if tellers.include?(m)
          x.mpname({:id => m.id, :vote => vote, :teller => "yes"}, m.name.full_name)
        else
          x.mpname({:id => m.id, :vote => vote}, m.name.full_name)
        end
      end
    end
  end
    
end
require 'section'

class Division < Section
  def initialize(yes, no, yes_tellers, no_tellers, pairs, time, url, count, division_count, date, house, logger = nil)
    @yes, @no, @yes_tellers, @no_tellers, @pairs, @division_count = yes, no, yes_tellers, no_tellers, pairs, division_count
    super(time, url, count, date, house, logger)
  end
  
  def output(x)
    x.division(:id => id, :nospeaker => "true", :divdate => @date, :divnumber => @division_count, :time => @time, :url => quoted_url) do
      
      x.divisioncount(:ayes => @yes.size, :noes => @no.size,
        :tellerayes => @yes_tellers.size, :tellernoes => @no_tellers.size)
      output_vote_list(x, @yes, @yes_tellers, "aye")
      output_vote_list(x, @no, @no_tellers, "no")
    end
  end
  
  private

  def output_vote_list(x, members, tellers, vote)
    x.memberlist(:vote => vote) do
      members.each do |m|
        attributes = {:id => m.id, :vote => vote}
        attributes[:teller] = "yes" if tellers.include?(m)
        x.member(attributes, m.name.full_name)
      end
    end
  end
    
end
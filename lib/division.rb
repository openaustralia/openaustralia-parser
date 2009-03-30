require 'section'

class Division < Section
  def initialize(yes, no, time, url, major_count, minor_count, date, house, logger = nil)
    @yes, @no = yes, no
    super(time, url, major_count, minor_count, date, house, logger)
  end
  
  def output(x)
    x.division(:id => id, :nospeaker => "true", :divdate => @date, :time => @time, :url => quoted_url) do
      # TODO: Tellers not yet implemented
      x.divisioncount(:ayes => @yes.size, :noes => @no.size, :tellerayes => 1, :tellernoes => 1)
      output_vote_list(x, @yes, "aye")
      output_vote_list(x, @no, "no")
    end
  end
  
  private

  def output_vote_list(x, members, vote)
    x.mplist(:vote => vote) do
      members.each do |m|
        x.mpname({:id => m.id, :vote => vote}, m.name.full_name)
      end
    end
  end
    
end
require 'section'

class Division < Section
  def initialize(yes, no, yes_tellers, no_tellers, pairs, time, url, bill_id, count, division_count, date, house, logger = nil)
    @yes, @no, @yes_tellers, @no_tellers, @pairs, @division_count, @bill_id = yes, no, yes_tellers, no_tellers, pairs, division_count, bill_id
    super(time, url, count, date, house, logger)
  end

  def output(x)
    division_attributes = {:id => id, :nospeaker => "true", :divdate => @date, :divnumber => @division_count, :time => @time, :url => quoted_url}
    division_attributes[:bill_id] = @bill_id if @bill_id != nil
    division_attributes[:bill_url] = @bill_id.split('; ').map { |e|
      "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:legislation/billhome/#{e}"
    }.join("; ") if @bill_id != nil
    x.division(division_attributes) do
      count_attributes = {:ayes => @yes.size, :noes => @no.size,
        :tellerayes => @yes_tellers.size, :tellernoes => @no_tellers.size}
      count_attributes[:pairs] = @pairs.size if @pairs.size > 0
      x.divisioncount(count_attributes)
      output_vote_list(x, @yes, @yes_tellers, "aye")
      output_vote_list(x, @no, @no_tellers, "no")
      # Output pairs votes
      if @pairs.size > 0
        x.pairs do
          @pairs.each do |pair|
            x.pair do
              x.member({:id => pair.first.id}, pair.first.name.full_name)
              x.member({:id => pair.last.id}, pair.last.name.full_name)
            end
          end
        end
      end
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
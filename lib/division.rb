# frozen_string_literal: true

require "section"

class Division < Section
  def initialize(yes_members, no_members, yes_tellers, no_tellers, pairs, time, url, bills, count, division_count, date, house, logger = nil)
    @yes = yes_members
    @no = no_members
    @yes_tellers = yes_tellers
    @no_tellers = no_tellers
    @pairs = pairs
    @division_count = division_count
    @bills = bills
    super(time, url, count, date, house, logger)
  end

  def output(builder)
    division_attributes = { id: id, nospeaker: "true", divdate: @date, divnumber: @division_count, time: @time, url: quoted_url }
    builder.division(division_attributes) do
      if @bills && !@bills.empty?
        builder.bills do
          @bills.each do |bill|
            builder.bill({ id: bill[:id], url: bill[:url] }, bill[:title])
          end
        end
      end
      count_attributes = { ayes: @yes.size, noes: @no.size,
                           tellerayes: @yes_tellers.size, tellernoes: @no_tellers.size }
      count_attributes[:pairs] = @pairs.size unless @pairs.empty?
      builder.divisioncount(count_attributes)
      output_vote_list(builder, @yes, @yes_tellers, "aye")
      output_vote_list(builder, @no, @no_tellers, "no")
      # Output pairs votes
      unless @pairs.empty?
        builder.pairs do
          @pairs.each do |pair|
            builder.pair do
              builder.member({ id: pair.first.id }, pair.first.name.full_name)
              builder.member({ id: pair.last.id }, pair.last.name.full_name)
            end
          end
        end
      end
    end
  end

  private

  def output_vote_list(builder, members, tellers, vote)
    builder.memberlist(vote: vote) do
      members.each do |m|
        attributes = { id: m.id, vote: vote }
        attributes[:teller] = "yes" if tellers.include?(m)
        builder.member(attributes, m.name.full_name)
      end
    end
  end
end

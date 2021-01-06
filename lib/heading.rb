# frozen_string_literal: true

class HeadingBase
  def initialize(title:, count:, url:, bills:, date:, house:)
    @title = title
    @count = count
    @url = url
    @bills = bills
    @date = date
    @house = house
  end

  def id
    if @house.representatives?
      "uk.org.publicwhip/debate/#{@date}.#{@count}"
    else
      "uk.org.publicwhip/lords/#{@date}.#{@count}"
    end
  end
end

class MajorHeading < HeadingBase
  def output(builder)
    builder.tag!("major-heading", id: id, url: @url) { builder << @title }
  end
end

class MinorHeading < HeadingBase
  def output(builder)
    parameters = { id: id, url: @url }
    builder.tag!("minor-heading", parameters) { builder << @title }
    return unless @bills && !@bills.empty?

    builder.bills do
      @bills.each do |bill|
        builder.bill({ id: bill[:id], url: bill[:url] }, bill[:title])
      end
    end
  end
end

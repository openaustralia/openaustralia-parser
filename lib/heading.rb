class HeadingBase
  def initialize(title, count, url, bill_url, date, house)
    @title, @count, @url, @bill_url, @date, @house = title, count, url, bill_url, date, house
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
  def output(x)
    parameters = {:id => id, :url => @url}
    parameters[:bill_url] = @bill_url if @bill_url != nil
    x.tag!("major-heading",parameters) { x << @title }
  end
end

class MinorHeading < HeadingBase
  def output(x)
    x.tag!("minor-heading", :id => id, :url => @url) { x << @title }
  end
end

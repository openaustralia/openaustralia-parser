class HeadingBase
  def initialize(title, count, url, date, house)
    @title, @count, @url, @date, @house = title, count, url, date, house
  end
  
  def id
    case @house
    when House.representatives
      "uk.org.publicwhip/debate/#{@date}.#{@count}"
    else
      "uk.org.publicwhip/lords/#{@date}.#{@count}"      
    end
  end
end

class MajorHeading < HeadingBase
  def output(x)
    x.tag!("major-heading", :id => id, :url => @url) { x << @title }
  end
end

class MinorHeading < HeadingBase
  def output(x)
    x.tag!("minor-heading", :id => id, :url => @url) { x << @title }
  end
end

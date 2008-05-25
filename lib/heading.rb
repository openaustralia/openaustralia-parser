class Heading
  def initialize(title, count, url, date)
    @title = title
    @count = count
    @url = url
    @date = date
  end
  
  def id
    "uk.org.publicwhip/debate/#{@date}.#{@count}"
  end
end

class MajorHeading < Heading
  def output(x)
    x.tag!("major-heading", @title, :id => id, :url => @url)
  end
end

class MinorHeading < Heading
  def output(x)
    x.tag!("minor-heading", @title, :id => id, :url => @url)
  end
end

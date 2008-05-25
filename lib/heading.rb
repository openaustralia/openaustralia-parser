class Heading
  def initialize(title, major_count, minor_count, url, date)
    @title = title
    @major_count = major_count
    @minor_count = minor_count
    @url = url
    @date = date
  end
  
  def id
    "uk.org.publicwhip/debate/#{@date}.#{@major_count}.#{@minor_count}"
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

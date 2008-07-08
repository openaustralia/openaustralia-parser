class HeadingBase
  def initialize(title, major_count, minor_count, url, date)
    @title = title
    @major_count = major_count
    @minor_count = minor_count
    @url = url
    @date = date
  end
  
end

class HouseHeading < HeadingBase
  def id
    "uk.org.publicwhip/debate/#{@date}.#{@major_count}.#{@minor_count}"
  end
end

class SenateHeading < HeadingBase
  def id
    "uk.org.publicwhip/lords/#{@date}.#{@major_count}.#{@minor_count}"
  end
end

# Oh my... What am I doing? :-)

class MajorHouseHeading < HouseHeading
  def output(x)
    x.tag!("major-heading", @title, :id => id, :url => @url)
  end
end

class MinorHouseHeading < HouseHeading
  def output(x)
    x.tag!("minor-heading", @title, :id => id, :url => @url)
  end
end

class MajorSenateHeading < SenateHeading
  def output(x)
    x.tag!("major-heading", @title, :id => id, :url => @url)
  end
end

class MinorSenateHeading < SenateHeading
  def output(x)
    x.tag!("minor-heading", @title, :id => id, :url => @url)
  end
end

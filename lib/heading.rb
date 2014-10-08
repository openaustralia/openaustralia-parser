class HeadingBase
  def initialize(title, count, url, bill_id, date, house)
    @title, @count, @url, @bill_id, @date, @house = title, count, url, bill_id, date, house
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
    x.tag!("major-heading", :id => id, :url => @url) { x << @title }
  end
end

class MinorHeading < HeadingBase
  def output(x)
    parameters = {:id => id, :url => @url}
    parameters[:bill_id] = @bill_id if @bill_id != nil
    parameters[:bill_url] = @bill_id.split('; ').map { |e|
      "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:legislation/billhome/#{e}"
    }.join("; ") if @bill_id != nil
    x.tag!("minor-heading", parameters) { x << @title }
  end
end

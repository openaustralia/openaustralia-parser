class HeadingBase
  def initialize(title, count, url, bills, date, house)
    @title, @count, @url, @bills, @date, @house = title, count, url, bills, date, house
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
    x.tag!("minor-heading", parameters) { x << @title }
    if @bills && !@bills.empty?
      x.bills do
        @bills.each do |bill|
          x.bill({:id => bill[:id], :url => "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:legislation/billhome/#{bill[:id]}"}, bill[:title])
        end
      end
    end
  end
end

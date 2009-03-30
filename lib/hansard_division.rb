class HansardDivision
  def initialize(content, day)
    @content, @day = content, day
  end
  
  def permanent_url
    @day.permanent_url
  end
  
  # Return an array of the names of people that voted yes
  def yes
    raw_yes.map {|text| HansardDivision.name(text)}
  end

  # And similarly for the people that voted no
  def no
    raw_no.map {|text| HansardDivision.name(text)}
  end
  
  def yes_tellers
    raw_yes.find_all {|text| HansardDivision.teller?(text)}.map {|text| HansardDivision.name(text)}
  end
  
  def no_tellers
    raw_no.find_all {|text| HansardDivision.teller?(text)}.map {|text| HansardDivision.name(text)}
  end
  
  def time
    tag = @content.at('(division.header) > (time.stamp)')
    tag.inner_html if tag
  end
  
  private

  def raw_yes
    @content.search("(division.data) > ayes > names > name").map {|e| e.inner_html}
  end
  
  def raw_no
    @content.search("(division.data) > noes > names > name").map {|e| e.inner_html}
  end
  
  def self.name(text)
    text =~ /^(.*) \*$/ ? $~[1] : text
  end
  
  def self.teller?(text)
    text =~ /^(.*) \*$/
  end
end
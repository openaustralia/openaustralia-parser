class HansardDivision
  def initialize(content)
    @content = content
  end
  
  # Return an array of the names of people that voted yes
  def yes
    raw_yes.map {|name| HansardDivision.strip_trailing_asterisk(name)}
  end

  # And similarly for the people that voted no
  def no
    raw_no.map {|name| HansardDivision.strip_trailing_asterisk(name)}
  end
  
  def yes_tellers
    raw_yes.find_all {|name| HansardDivision.teller?(name)}.map {|name| HansardDivision.strip_trailing_asterisk(name)}
  end
  
  def no_tellers
    raw_no.find_all {|name| HansardDivision.teller?(name)}.map {|name| HansardDivision.strip_trailing_asterisk(name)}
  end
  
  def time
    tag = @content.at('> division > (division.header) > (time.stamp)')
    tag.inner_html if tag
  end
  
  private

  def raw_yes
    @content.search("> division > (division.data) > ayes > names > name").map {|e| e.inner_html}
  end
  
  def raw_no
    @content.search("> division > (division.data) > noes > names > name").map {|e| e.inner_html}
  end
  
  def HansardDivision.strip_trailing_asterisk(name)
    name =~ /^(.*) \*$/ ? $~[1] : name
  end
  
  def HansardDivision.teller?(name)
    name =~ /^(.*) \*$/
  end
end
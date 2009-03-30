class HansardDivision
  def initialize(content)
    @content = content
  end
  
  # Return an array of the names of people that voted yes
  def yes
    @content.search("> division > (division.data) > ayes > names > name").map {|e| e.inner_html}
  end

  # And similarly for the people that voted no
  def no
    @content.search("> division > (division.data) > noes > names > name").map {|e| e.inner_html}
  end
  
  def time
    tag = @content.at('> division > (division.header) > (time.stamp)')
    tag.inner_html if tag
  end
end
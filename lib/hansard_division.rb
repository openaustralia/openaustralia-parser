require 'enumerator'

class HansardDivision
  attr_reader :title, :subtitle
  
  def initialize(content, title, subtitle, day)
    @content, @title, @subtitle, @day = content, title, subtitle, day
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
  
  def pairs
    names = @content.search("(division.data) > pairs > names > name").map {|e| e.inner_html}
    raise "Not an even number of people in the pairs voting" if names.size % 2 != 0
    # Format the flat list of names into pairs (assuming that the people in pairs appear consecutively)
    pairs = []
    names.each_slice(2) { |p| pairs << p }
    pairs
  end
  
  def yes_tellers
    raw_yes.find_all {|text| HansardDivision.teller?(text)}.map {|text| HansardDivision.name(text)}
  end
  
  def no_tellers
    raw_no.find_all {|text| HansardDivision.teller?(text)}.map {|text| HansardDivision.name(text)}
  end
  
  def time
    tag = @content.at('(division.header) > (time.stamp)')
    time = tag.inner_html if tag
    # if no timestamp, fallback to extracting out of preamble
    if !time && (header = @content.at('(division.header)'))
      results = header.inner_html.match(/\[(..:..)\]/)
      time = results[1] if results
    end
    time
  end
  
  private

  def raw_yes
    @content.search("(division.data) > ayes > names > name").map {|e| e.inner_html}
  end
  
  def raw_no
    @content.search("(division.data) > noes > names > name").map {|e| e.inner_html}
  end
  
  def self.name(text)
    text =~ /^(.*)\*$/ ? $~[1].strip : text
  end
  
  def self.teller?(text)
    text =~ /^(.*)\*$/
  end
end

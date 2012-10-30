require 'heading'
require 'speech'
require 'division'
require 'count'

# Holds the data for debates on one day
# Also knows how to output the XML data for that
class Debates
  def initialize(date, house, logger = nil)
    @date, @house, @logger = date, house, logger
    @title = ""
    @subtitle = ""
    @items = []
    @count = Count.new
    @division_count = 1
    @latest_major_heading = nil
    @latest_minor_heading = nil
  end
  
  def add_heading(newtitle, newsubtitle, url)
    # Only add headings if they have changed
    if newtitle != @title
      @latest_major_heading = MajorHeading.new(newtitle, @count.clone, url, @date, @house)
      @count.increment_minor
    end
    if newtitle != @title || newsubtitle != @subtitle
      @latest_minor_heading = MinorHeading.new(newsubtitle, @count.clone, url, @date, @house)
      @count.increment_minor
    end
    @title = newtitle
    @subtitle = newsubtitle
  end
  
  def add_heading_for_real
    if @latest_major_heading
      @items << @latest_major_heading
      @latest_major_heading = nil
    end
    if @latest_minor_heading
      @items << @latest_minor_heading
      @latest_minor_heading = nil
    end
  end
  
  def increment_minor_count
    @count.increment_minor
  end
  
  def increment_major_count
    @count.increment_major
  end
  
  def increment_division_count
    @division_count = @division_count + 1
  end
  
  def add_speech(speaker, time, url, content, interjection=false, continuation=false)
    add_heading_for_real
    
    # Only add new speech if the speaker has changed
    if !@items.last.kind_of?(Speech) || speaker != last_speaker
      speech = Speech.new(speaker, time, url, @count.clone, @date, @house, @logger)
      speech.interjection = interjection
      speech.continuation = continuation
      @items << speech
    end
    @items.last.append_to_content(content)
  end
  
  def add_division(yes, no, yes_tellers, no_tellers, pairs, time, url)
    add_heading_for_real

    @items << Division.new(yes, no, yes_tellers, no_tellers, pairs, time, url, @count.clone, @division_count, @date, @house, @logger)
    increment_division_count
  end
  
  def last_speaker
    @items.last.speaker if @items.last.respond_to?(:speaker)
  end
  
  def output_builder(x)
    x.instruct!
    x.debates do
      @items.each {|i| i.output(x)}
    end
  end
  
  def output(xml_filename)
    xml = File.open(xml_filename, 'w')
    x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
    output_builder(x)
    
    xml.close
  end  
end

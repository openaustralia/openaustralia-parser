require 'heading'

# Holds the data for debates on one day
# Also knows how to output the XML data for that
class Debates
  def initialize(date)
    @date = date
    @title = ""
    @subtitle = ""
    @items = []
    @minor_count = 1
    @major_count = 1
  end
  
  def add_heading(newtitle, newsubtitle, url)
    # Only add headings if they have changed
    if newtitle != @title
      @items << MajorHeading.new(newtitle, @major_count, @minor_count, url, @date)
      increment_minor_count
    end
    if newtitle != @title || newsubtitle != @subtitle
      @items << MinorHeading.new(newsubtitle, @major_count, @minor_count, url, @date)
      increment_minor_count
    end
    @title = newtitle
    @subtitle = newsubtitle    
  end
  
  def increment_minor_count
    @minor_count = @minor_count + 1
  end
  
  def increment_major_count
    @major_count = @major_count + 1
    @minor_count = 1
  end
  
  def add_rep_speech(speaker, time, url, content)
    # Only add new speech if the speaker has changed
    unless speaker && last_speaker && speaker == last_speaker
      @items << HouseSpeech.new(speaker, time, url, @major_count, @minor_count, @date)
    end
    @items.last.append_to_content(content)
  end
  
  def add_senator_speech(speaker, time, url, content)
    # Only add new speech if the speaker has changed
    unless speaker && last_speaker && speaker == last_speaker
      @items << SenateSpeech.new(speaker, time, url, @major_count, @minor_count, @date)
    end
    @items.last.append_to_content(content)
  end
  
  def last_speaker
    @items.last.speaker unless @items.empty? || !@items.last.respond_to?(:speaker)
  end
  
  def output(xml_filename)
    xml = File.open(xml_filename, 'w')
    x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
    x.instruct!
    x.publicwhip do
      @items.each {|i| i.output(x)}
    end
    
    xml.close
  end
end

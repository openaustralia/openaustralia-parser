require 'heading'

# Holds the data for debates on one day
# Also knows how to output the XML data for that
class Debates
  def initialize(date, house)
    @date = date
    @house = house
    @title = ""
    @subtitle = ""
    @items = []
    @minor_count = 1
    @major_count = 1
  end
  
  def add_heading(newtitle, newsubtitle, url)
    # Only add headings if they have changed
    if newtitle != @title
      @items << new_major_heading(newtitle, @major_count, @minor_count, url, @date)
      increment_minor_count
    end
    if newtitle != @title || newsubtitle != @subtitle
      @items << new_minor_heading(newsubtitle, @major_count, @minor_count, url, @date)
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
  
  def add_speech(speaker, time, url, content)
    # Only add new speech if the speaker has changed
    unless speaker && last_speaker && speaker == last_speaker
      @items << new_speech(speaker, time, url, @major_count, @minor_count, @date)
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
  
  def new_speech(speaker, time, url, major_count, minor_count, date)
    if @house.representatives?
      HouseSpeech.new(speaker, time, url, major_count, minor_count, date)
    else
      SenateSpeech.new(speaker, time, url, major_count, minor_count, date)
    end
  end

  def new_major_heading(text, major_count, minor_count, url, date)
    if @house.representatives?
      MajorHouseHeading.new(text, major_count, minor_count, url, date)
    else
      MajorSenateHeading.new(text, major_count, minor_count, url, date)
    end
  end
  
  def new_minor_heading(text, major_count, minor_count, url, date)
    if @house.representatives?
      MinorHouseHeading.new(text, major_count, minor_count, url, date)
    else
      MinorSenateHeading.new(text, major_count, minor_count, url, date)
    end
  end  
end

require 'environment'
require 'hpricot'
require 'htmlentities'
require 'section'

class Speech < Section
  attr_accessor :speaker, :content, :interjection, :continuation
  
  def initialize(speaker, time, url, count, date, house, logger = nil)
    @speaker = speaker
    @content = Hpricot::Elements.new
    super(time, url, count, date, house, logger)
  end
  
  def output(x)
    time = @time.nil? ? "unknown" : @time
    if @logger && @content.inner_text.strip == ""
      if @speaker.nil?
        @logger.error "#{@date} #{@house}: Empty speech in procedural text"
      else
        @logger.error "#{@date} #{@house}: Empty speech by #{@speaker.person.name.full_name}"
      end
    end
    speaker_attributes = @speaker ? {:speakername => @speaker.name.full_name, :speakerid => @speaker.id} : {:nospeaker => "true"}
    x.speech(speaker_attributes.merge(:time => time, :url => quoted_url, :id => id, :talktype => talk_type)) { x << @content.to_s }
  end
  
  def append_to_content(content)
    # Put entities back into the content so that, for instance, '&' becomes '&amp;'
    # Since we are outputting XML rather than HTML in order to save us the trouble of putting the HTML entities in the XML
    # we are only encoding the basic XML entities
    coder = HTMLEntities.new
    content.traverse_text do |text|
      text.swap(coder.encode(text, :basic))
    end
    # Append to stored content
    if content.kind_of?(Array)
      @content = @content + content
    else
      @content << content
    end
  end

  def talk_type
    if @interjection
      'interjection'
    elsif @continuation
      'continuation'
    else
      'speech'
    end
  end
end

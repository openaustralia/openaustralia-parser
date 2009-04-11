require 'hpricot'
require 'htmlentities'
require 'section'

class Speech < Section
  attr_accessor :speaker, :content
  
  def initialize(speaker, time, url, major_count, minor_count, date, house, logger = nil)
    throw "speaker can't be nil in Speech" if speaker.nil?
    @speaker = speaker
    @content = Hpricot::Elements.new
    super(time, url, major_count, minor_count, date, house, logger)
  end
  
  def output(x)
    time = @time.nil? ? "unknown" : @time
    if @logger && @content.inner_text.strip == ""
      @logger.error "#{@date} #{@house}: Empty speech by #{@speaker.person.name.full_name} on #{@url}"
    end
    x.speech(:speakername => @speaker.name.full_name, :time => time, :url => quoted_url, :id => id,
      :speakerid => @speaker.id) { x << @content.to_s }
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
end

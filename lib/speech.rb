require 'hpricot'
require 'htmlentities'

class Speech
  attr_accessor :speaker, :time, :url, :id, :content
  
  def initialize(speaker, time, url, major_count, minor_count, date, house, logger = nil)
    throw "speaker can't be nil in Speech" if speaker.nil?
    @speaker, @time, @url, @major_count, @minor_count, @date, @house, @logger  =
      speaker, time, url, major_count, minor_count, date, house, logger
    @content = Hpricot::Elements.new
  end
  
  def output(x)
    time = @time.nil? ? "unknown" : @time
    if @logger && @content.inner_text.strip == ""
      @logger.error "Empty speech by #{@speaker.person.name.full_name} on #{@url}"
    end
    x.speech(:speakername => @speaker.name.full_name, :time => time, :url => url_quote(@url), :id => id,
      :speakerid => @speaker.id) { x << @content.to_s }
  end
  
  # Quoting of url's is required to be nice and standards compliant
  def url_quote(url)
    url.gsub('&', '&amp;')
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
  
  def id
    if @house.representatives?
      "uk.org.publicwhip/debate/#{@date}.#{@major_count}.#{@minor_count}"
    else
      "uk.org.publicwhip/lords/#{@date}.#{@major_count}.#{@minor_count}"
    end
  end
end

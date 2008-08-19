require 'rubygems'
require 'hpricot'
require 'htmlentities'

class Speech
  attr_accessor :speaker, :time, :url, :id, :content
  
  def initialize(speaker, time, url, major_count, minor_count, date, house, logger = nil, sub_page_permanent_url = nil)
    @speaker, @time, @url, @major_count, @minor_count, @date, @house, @logger, @sub_page_permanent_url =
      speaker, time, url, major_count, minor_count, date, house, logger, sub_page_permanent_url
    @content = Hpricot::Elements.new
  end
  
  def output(x)
    time = @time.nil? ? "unknown" : @time
    if @logger && @content.inner_text.strip == ""
      @logger.error "Empty speech by #{@speaker.person.name.full_name} on #{@sub_page_permanent_url}"
    end
    if @speaker
      x.speech(:speakername => @speaker.name.full_name, :time => time, :url => url_quote(@url), :id => id,
        :speakerid => @speaker.id) { x << @content.to_s }
    else
      x.speech(:speakername => "unknown", :time => time, :url => url_quote(@url), :id => id) { x << @content.to_s }
    end
  end
  
  # Quoting of url's is required to be nice and standards compliant
  def url_quote(url)
    url.gsub('&', '&amp;')
  end
  
  def append_to_content(content)
    # Put html entities back into the content so that, for instance, '&' becomes '&amp;'
    coder = HTMLEntities.new
    content.traverse_text do |text|
      text.swap(coder.encode(text, :named))
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

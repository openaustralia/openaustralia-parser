class Speech
  attr_accessor :speaker, :time, :url, :id, :content
  
  def initialize(speaker, time, url, major_count, minor_count, date, house, logger, sub_page_permanent_url)
    @speaker, @time, @url, @major_count, @minor_count, @date, @house, @logger, @sub_page_permanent_url =
      speaker, time, url, major_count, minor_count, date, house, logger, sub_page_permanent_url
    @content = Hpricot::Elements.new
  end
  
  def output(x)
    time = @time.nil? ? "unknown" : @time
    if @content.inner_text.strip == ""
      @logger.error "Empty speech by #{@speaker.person.name.full_name} on #{@sub_page_permanent_url}"
    end
    if @speaker
      x.speech(:speakername => @speaker.name.full_name, :time => time, :url => @url, :id => id,
        :speakerid => @speaker.id) { x << @content.to_s }
    else
      x.speech(:speakername => "unknown", :time => time, :url => @url, :id => id) { x << @content.to_s }
    end
  end

  def append_to_content(content)
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

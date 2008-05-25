class Speech
  attr_accessor :speaker, :time, :url, :id, :content
  
  def initialize(speaker, time, url, major_count, minor_count, date)
    @speaker = speaker
    @time = time
    @url = url
    @major_count = major_count
    @minor_count = minor_count
    @date = date
    @content = Hpricot::Elements.new
  end
  
  def id
    "uk.org.publicwhip/debate/#{@date}.#{@major_count}.#{@minor_count}"
  end

  def output(x)
    if @speaker
      x.speech(:speakername => @speaker.name.full_name, :time => @time, :url => @url, :id => id,
        :speakerid => @speaker.id) { x << @content.to_s }
    else
      x.speech(:speakername => "unknown", :time => @time, :url => @url, :id => id) { x << @content.to_s }
    end
  end

  def append_to_content(content)
    if content.kind_of?(Array)
      @content = @content + content
    else
      @content << content
    end
  end
end


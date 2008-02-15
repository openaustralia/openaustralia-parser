class Speech
  attr_accessor :speaker, :time, :url, :id, :content
  
  def initialize(speaker = nil, time = nil, url = nil, id = nil, content = Hpricot::Elements.new)
    @speaker = speaker
    @time = time
    @url = url
    @id = id
    @content = content
  end
  
  def output(x)
    if @speaker
      x.speech(:speakername => @speaker.person.name.full_name, :time => @time, :url => @url, :id => @id,
        :speakerid => @speaker.id) { x << @content.to_s }
    else
      x.speech(:speakername => "unknown", :time => @time, :url => @url, :id => @id) { x << @content.to_s }
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


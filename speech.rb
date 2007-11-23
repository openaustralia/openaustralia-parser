class Speech
  attr_accessor :speakername, :time, :url, :id, :speakerid, :content
  
  def initialize(speakername = nil, time = nil, url = nil, id = nil, speakerid = nil, content = Hpricot::Elements.new)
    @speakername = speakername
    @time = time
    @url = url
    @id = id
    @speakerid = speakerid
    @content = content
  end
  
  def output(x)
    x.speech(:speakername => @speakername, :time => @time, :url => @url, :id => @id,
      :speakerid => @speakerid) { x << @content.to_s }
  end

  def append_to_content(content)
    if content.kind_of?(Array)
      @content = @content + content
    else
      @content << content
    end
  end
end


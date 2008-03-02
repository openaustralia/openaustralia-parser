# Merges together two or more speeches by the same person that occur consecutively
class Speeches
  def initialize
    @speeches = []
  end
  
  def add_speech(speaker, time, url, speech_id, content)
    if speaker.nil? || @speeches.empty? || @speeches.last.speaker.nil? || speaker != @speeches.last.speaker
      @speeches << Speech.new(speaker, time, url, speech_id)
    end
    @speeches.last.append_to_content(content)
  end
  
  def write(x)
    @speeches.each {|s| s.output(x)}
  end
end

require 'hansard_speech'

class HansardPage
  def initialize(page, title, subtitle, time, day, logger = nil)
    @page, @title, @subtitle, @time, @day, @logger = page, title, subtitle, time, day, logger
  end
  
  # Returns an array of speech objects that contain a person making a speech
  # if an element is nil it should be skipped but the minor_count should still be incremented
  def speeches
    speech_blocks = []
    # Assume here that @page is in fact an array
    @page.each do |e|
      case e.name
      when 'speech', 'question', 'answer'
        # Add each child as a seperate speech_block
        e.each_child_node do |c|
          speech_blocks << HansardSpeech.new(c, @title, @subtitle, @time, @day, @logger)
        end
      else
        throw "Unexpected tag #{e.name}"
      end
    end
    speech_blocks
  end  
end

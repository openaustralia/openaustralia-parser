require 'hansard_speech'
require 'configuration'

class HansardPage
  attr_reader :page, :logger, :day
  
  def initialize(page, title, subtitle, day, logger = nil)
    @page, @title, @subtitle, @day, @logger = page, title, subtitle, day, logger
    @conf = Configuration.new
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
          speech_blocks << c
        end
      else
        throw "Unexpected tag #{e.name}"
      end
    end
    
    speech_blocks.map {|e| HansardSpeech.new(e, @title, @subtitle, self, logger) if e}
  end  

  # Returns the time (as a string) that the current debate took place
  def time
    # HACK: Hmmm.. check this out more 
    tag = @page.first.at('(time.stamp)')
    tag.inner_html if tag
  end  
end

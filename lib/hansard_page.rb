require 'hansard_speech'
require 'configuration'

class HansardPage
  attr_reader :page, :logger
  
  # 'link' is the link that got us to this page 'page'
  def initialize(page, title, subtitle, day, logger = nil)
    @page, @title, @subtitle, @day, @logger = page, title, subtitle, day, logger
    @conf = Configuration.new
  end
  
  def in_proof?
    @day.in_proof?
  end
  
  def permanent_url
    @day.permanent_url
  end

  # A single string that contains the title and subtitle in one
  def full_hansard_title
    if hansard_subtitle != ""
      hansard_title + "; " + hansard_subtitle
    else
      hansard_title
    end
  end

  def hansard_title
    @title
  end
  
  def hansard_subtitle
    @subtitle
  end
  
  def has_content?
    !speeches.empty?
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

          # HACK: If tag is a quote we really should add all the children rather than the tag itself. However
          # this will lose the 'quote' information. So, we are working around this by just adding the correct
          # number of nil speeches so that the minor id's will match up.
          if c.name == 'quote'
            c.each_child_node {|d| speech_blocks << nil}
            # Remove one of the ones I just added.
            speech_blocks.pop
          end
        end
      else
        throw "Unexpected tag #{e.name}"
      end
    end
    
    speech_blocks.map {|e| HansardSpeech.new(e, self, logger) if e}
  end  

  # Returns the time (as a string) that the current debate took place
  def time
    # HACK: Hmmm.. check this out more 
    tag = @page.first.at('(time.stamp)')
    tag.inner_html if tag
  end  
end

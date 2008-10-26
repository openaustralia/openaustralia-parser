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
        end
      else
        throw "Unexpected tag #{e.name}"
      end
    end
    
    #@page.children.each do |e|
    #  next unless e.respond_to?(:name)
    #  if ['speech', 'question', 'answer'].include?(e.name)
    #    # Add each child as a seperate speech_block
    #    e.children.each do |c|
    #      next unless c.respond_to?(:name)
    #      speech_blocks << c
    #    end
    #  elsif e.name == 'motionnospeech'
    #    #speech_blocks << e
    #  elsif ['interjection', 'debateinfo', 'subdebateinfo', 'division', 'para', 'motion', 'quote'].include?(e.name)
    #    # Skip
    #  else
    #    throw "Don't know what to do with the tag #{e.name} yet"
    #  end
    #end
 
    return speech_blocks.map {|e| HansardSpeech.new(e, self, logger) if e}
    
    #
    
    content_start.children.each do |e|
      break unless e.respond_to?(:attributes)
      
      class_value = e.attributes["class"]
      if e.name == "div"
        if class_value == "hansardtitlegroup" || class_value == "hansardsubtitlegroup"
        elsif class_value == "speech0" || class_value == "speech1"
          e.children[1..-1].each do |e|
            speech_blocks << e
          end
        elsif class_value == "motionnospeech" || class_value == "subspeech0" || class_value == "subspeech1" ||
            class_value == "motion" || class_value = "quote"
          speech_blocks << e
        else
          throw "Unexpected class value #{class_value} for tag #{e.name}"
        end
      elsif e.name == "p"
        speech_blocks << e
      elsif e.name == "table"
        if class_value == "division"
          # By adding nil the minor_count will be incremented
          speech_blocks << nil
        else
          throw "Unexpected class value #{class_value} for tag #{e.name}"
        end
      else
        throw "Unexpected tag #{e.name}"
      end
    end
    speech_blocks.map {|e| HansardSpeech.new(e, self, logger) if e}
  end  

  # Returns the time (as a string) that the current debate took place
  def time
    "??"
  end  
end

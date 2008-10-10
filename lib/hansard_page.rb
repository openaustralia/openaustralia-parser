require 'hansard_speech'
require 'configuration'

class HansardPage
  attr_reader :page, :link, :logger
  
  # 'link' is the link that got us to this page 'page'
  def initialize(page, link, logger)
    @page, @link, @logger = page, link, logger
    @conf = Configuration.new
  end
  
  def in_proof?
    proof = extract_metadata_tags["Proof"]
    logger.error "Unexpected value '#{proof}' for metadata 'Proof'" unless proof == "Yes" || proof == "No"
    proof == "Yes"
  end

  # Extract a hash of all the metadata tags and values
  def extract_metadata_tags
    # Start point of search for all metadata
    a = @page.search("table#dlMetadata")
    i = 0
    metadata = {}
    while true
      label_tag = a.search("span#dlMetadata__ctl#{i}_Label2").first
      value_tag = a.search("span#dlMetadata__ctl#{i}_Label3").first
      break if label_tag.nil? && value_tag.nil?
      metadata[label_tag.inner_text] = value_tag.inner_text.strip
      i = i + 1
    end
    metadata
  end
  
  def house
    text = @page.at('chamber').inner_html
    if text == "SENATE"
      House.senate
    elsif text == "REPS"
      House.representatives
    else
      throw "Unexpected value #{text} for contents of <chamber> tag"
    end
  end
  
  def date
    Date.parse(@page.at('date').inner_html)
  end
  
  def permanent_url
    house_letter = house.representatives? ? "r" : "s"
    "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:chamber/hansard#{house_letter}/#{date}/0000"
  end
  
  def hansard_title
    @page.search('div#contentstart div.hansardtitle').map { |m| m.inner_html }.join('; ')
  end
  
  def hansard_subtitle
    @page.search('div#contentstart div.hansardsubtitle').map { |m| m.inner_html }.join('; ')
  end
  
  def content_start
    @page.search('div#contentstart').first
  end
  
  # Returns an array of speech objects that contain a person making a speech
  # if an element is nil it should be skipped but the minor_count should still be incremented
  def speeches
    throw "No content in #{permanent_url}" if content_start.nil?
    
    speech_blocks = []
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

  # Is this a sub-page that we are currently supporting?
  def supported?
    @link.to_s =~ /^Speech:/ || @link.to_s =~ /^QUESTIONS? WITHOUT NOTICE/i || @link.to_s =~ /^QUESTIONS TO THE SPEAKER:/
  end
  
  def to_skip?
    @link.to_s == "Official Hansard" || @link.to_s =~ /^Start of Business/ || @link.to_s == "Adjournment"
  end
  
  def not_yet_supported?
    @link.to_s =~ /^Procedural text:/ || @link.to_s =~ /^QUESTIONS IN WRITING:/ || @link.to_s =~ /^Division:/ ||
      @link.to_s =~ /^REQUESTS? FOR DETAILED INFORMATION:/ ||
      @link.to_s =~ /^Petition:/ || @link.to_s =~ /^PRIVILEGE:/ || @link.to_s == "Interruption" ||
      @link.to_s =~ /^QUESTIONS? ON NOTICE:/i || @link.to_s =~ /^QUESTIONS TO THE SPEAKER/ ||
      # Hack to deal with incorrectly titled page on 31 Oct 2005
      @link.to_s =~ /^IRAQ/
  end  

  # Returns the time (as a string) that the current debate took place
  def time
    # Link text for speech has format:
    # HEADING > NAME > HOUR:MINS:SECS
    time = @link.to_s.split('>')[2]
    time.strip! unless time.nil?
    # Check that time is something valid
    unless time =~ /^\d\d:\d\d:\d\d$/
      logger.error "Time #{time} invalid on link #{@link}"
      time = nil
    end
    time
  end  
end

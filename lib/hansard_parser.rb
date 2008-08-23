require 'speech'
require 'mechanize_proxy'
require 'configuration'
require 'debates'
require 'builder_alpha_attributes'
require 'house'
require 'people_image_downloader'
# Using Active Support (part of Ruby on Rails) for Unicode support
require 'activesupport'

$KCODE = 'u'

class UnknownSpeaker
  def initialize(name)
    @name = name
  end
  
  def id
    "unknown"
  end
  
  def name
    Name.title_first_last(@name)
  end
end

require 'rubygems'
require 'log4r'

class HansardPage
  attr_reader :page, :link, :logger
  
  # 'link' is the link that got us to this page 'page'
  def initialize(page, link, logger)
    @page, @link, @logger = page, link, logger
  end
  
  def in_proof?
    proof = extract_metadata_tags["Proof"]
    logger.error "Unexpected value '#{proof}' for metadata 'Proof'" unless proof == "Yes" || proof == "No"
    proof == "Yes"
  end

  # Extract a hash of all the metadata tags and values
  def extract_metadata_tags
    i = 0
    metadata = {}
    while true
      label_tag = @page.search("span#dlMetadata__ctl#{i}_Label2").first
      value_tag = @page.search("span#dlMetadata__ctl#{i}_Label3").first
      break if label_tag.nil? && value_tag.nil?
      metadata[label_tag.inner_text] = value_tag.inner_text.strip
      i = i + 1
    end
    metadata
  end
  
  def permanent_url
    @page.links.text("[Permalink]").uri.to_s
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
  
  def parse_speech_block2(e, house)
    speakername, speaker_url, interjection = extract_speakername(e, house)
    aph_id = extract_aph_id_from_speaker_url(speaker_url)
    [speakername, aph_id, interjection, clean_speech_content(e, house)]
  end
  
  def extract_speakername(content, house)
    interjection = false
    speaker_url = nil
    # Try to extract speaker name from talkername tag
    tag = content.search('span.talkername a').first
    tag2 = content.search('span.speechname').first
    if tag
      name = tag.inner_html
      speaker_url = tag.attributes['href']
      # Now check if there is something like <span class="talkername"><a>Some Text</a></span> <b>(Some Text)</b>
      tag = content.search('span.talkername ~ b').first
      # Only use it if it is surrounded by brackets
      if tag && tag.inner_html.match(/\((.*)\)/)
        name += " " + $~[0]
      end
    elsif tag2
      name = tag2.inner_html
    # If that fails try an interjection
    elsif content.search("div.speechType").inner_html == "Interjection"
      interjection = true
      text = strip_tags(content.search("div.speechType + *").first)
      m = text.match(/([a-z].*) interjecting/i)
      if m
        name = m[1]
        talker_not_correctly_marked_up = true
      else
        m = text.match(/([a-z].*)—/i)
        if m
          name = m[1]
          talker_not_correctly_marked_up = true
        else
          name = nil
        end
      end
    # As a last resort try searching for interjection text
    else
      m = strip_tags(content).match(/([a-z].*) interjecting/i)
      if m
        name = m[1]
        talker_not_correctly_marked_up = true
        interjection = true
      else
        m = strip_tags(content).match(/^([a-z].*?)—/i)
        if m and generic_speaker?(m[1], house)
          name = m[1]
          talker_not_correctly_marked_up = true
        end
      end
    end
    
    if talker_not_correctly_marked_up
      logger.warn "Speech by #{name} not specified by talkername in #{permanent_url}" unless generic_speaker?(name, house) || logger.nil?
    end
    [name, speaker_url, interjection]
  end
  
  def clean_speech_content(content, house)
    doc = Hpricot(content.to_s)
    talkername_tags = doc.search('span.talkername ~ b ~ *')
    talkername_tags.each do |tag|
      if tag.to_s.chars[0..0] == '—'
        tag.swap(tag.to_s.chars[1..-1])
      end
    end
    talkername_tags = doc.search('span.talkername ~ *')
    talkername_tags.each do |tag|
      if tag.to_s.chars[0..0] == '—'
        tag.swap(tag.to_s.chars[1..-1])
      end
    end
    doc = remove_generic_speaker_names(doc, house)
    doc.search('div.speechType').remove
    doc.search('span.talkername ~ b').remove
    doc.search('span.talkername').remove
    doc.search('span.talkerelectorate').remove
    doc.search('span.talkerrole').remove
    doc.search('hr').remove
    make_motions_and_quotes_italic(doc)
    remove_subspeech_tags(doc)
    fix_links(doc)
    make_amendments_italic(doc)
    fix_attributes_of_p_tags(doc)
    fix_attributes_of_td_tags(doc)
    fix_motionnospeech_tags(doc)
    # Do pure string manipulations from here
    text = doc.to_s.chars.normalize(:c)
    text = text.gsub(/\(\d{1,2}.\d\d (a|p).m.\)—/, '')
    text = text.gsub('()', '')
    text = text.gsub('<div class="separator"></div>', '')
    # Look for tags in the text and display warnings if any of them aren't being handled yet
    text.scan(/<[a-z][^>]*>/i) do |t|
      m = t.match(/<([a-z]*) [^>]*>/i)
      if m
        tag = m[1]
      else
        tag = t[1..-2]
      end
      allowed_tags = ["b", "i", "dl", "dt", "dd", "ul", "li", "a", "table", "td", "tr", "img"]
      if !allowed_tags.include?(tag) && t != "<p>" && t != '<p class="italic">'
        logger.error "Tag #{t} is present in speech contents: #{text} on #{permanent_url}"
      end
    end
    # Reparse
    doc = Hpricot(text)
    doc.traverse_element do |node|
      text = node.to_s.chars
      if text[0..0] == '—' || text[0..0] == [160].pack('U*')
        node.swap(text[1..-1].to_s)
      end
    end
    doc
  end

  def remove_generic_speaker_names(content, house)
    name, speaker_url, interjection = extract_speakername(content, house)
    if generic_speaker?(name, house) and !interjection
      #remove everything before the first hyphen
      return Hpricot(content.to_s.gsub!(/^<p[^>]*>.*?—/i, "<p>"))
    end
    
    return content
  end

  def generic_speaker?(speakername, house)
    if house.representatives?
      speakername =~ /^(an? )?(honourable|opposition|government) members?$/i
    else
      speakername =~ /^(an? )?(honourable|opposition|government) senators?$/i
    end
  end

  def fix_motionnospeech_tags(content)
    content.search('div.motionnospeech').wrap('<p></p>')
    replace_with_inner_html(content, 'div.motionnospeech')
    content.search('span.speechname').remove
    content.search('span.speechelectorate').remove
    content.search('span.speechrole').remove
    content.search('span.speechtime').remove
  end
  
  def fix_attributes_of_p_tags(content)
    content.search('p.parabold').wrap('<b></b>')
    content.search('p').each do |e|
      class_value = e.get_attribute('class')
      if class_value == "block" || class_value == "parablock" || class_value == "parasmalltablejustified" ||
          class_value == "parasmalltableleft" || class_value == "parabold" || class_value == "paraheading" || class_value == "paracentre"
        e.remove_attribute('class')
      elsif class_value == "paraitalic"
        e.set_attribute('class', 'italic')
      elsif class_value == "italic" && e.get_attribute('style')
        e.remove_attribute('style')
      end
      e.remove_attribute('style')
    end
  end
  
  def fix_attributes_of_td_tags(content)
    content.search('td').each do |e|
      e.remove_attribute('style')
    end
  end
  
  def fix_links(content)
    content.search('a').each do |e|
      href_value = e.get_attribute('href')
      if href_value.nil?
        # Remove a tags
        e.swap(e.inner_html)
      else
        e.set_attribute('href', URI.join(permanent_url, href_value))
      end
    end
    content.search('img').each do |e|
      e.set_attribute('src', URI.join(permanent_url, e.get_attribute('src')))
    end
    content
  end

  def make_motions_and_quotes_italic(content)
    content.search('div.motion p').set(:class => 'italic')
    replace_with_inner_html(content, 'div.motion')
    content.search('div.quote p').set(:class => 'italic')
    replace_with_inner_html(content, 'div.quote')
    content
  end
  
  def make_amendments_italic(content)
    content.search('div.amendments div.amendment0 p').set(:class => 'italic')
    content.search('div.amendments div.amendment1 p').set(:class => 'italic')
    replace_with_inner_html(content, 'div.amendment0')
    replace_with_inner_html(content, 'div.amendment1')
    replace_with_inner_html(content, 'div.amendments')
    content
  end
  
  def remove_subspeech_tags(content)
    replace_with_inner_html(content, 'div.subspeech0')
    replace_with_inner_html(content, 'div.subspeech1')
    content
  end

  def replace_with_inner_html(content, search)
    content.search(search).each do |e|
      e.swap(e.inner_html)
    end
  end

  def strip_tags(doc)
    str=doc.to_s
    str.gsub(/<\/?[^>]*>/, "")
  end

  # Returns an array of blocks of html that contain a person making a speech
  # if a block is nil it should be skipped but the minor_count should still be incremented
  def speech_blocks
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
    speech_blocks
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

  def extract_aph_id_from_speaker_url(speaker_url)
    if speaker_url =~ /^view_document.aspx\?TABLE=biogs&ID=(\d+)$/
      $~[1].to_i
    elsif speaker_url.nil? || speaker_url == "view_document.aspx?TABLE=biogs&ID="
      nil
    else
      logger.error "Speaker link has unexpected format: #{speaker_url} on #{@page.permanent_url}"
      nil
    end
  end  
end

class HansardParser
  attr_reader :logger
  
  # people passed in initializer have to have their aph_id's set. This can be done by
  # calling PeopleImageDownloader.new.attach_aph_person_ids(people)
  def initialize(people)
    @people = people
    @conf = Configuration.new
    
    # Set up logging
    @logger = Log4r::Logger.new 'HansardParser'
    # Log to both standard out and the file set in configuration.yml
    @logger.add(Log4r::Outputter.stdout)
    @logger.add(Log4r::FileOutputter.new('foo', :filename => @conf.log_path, :trunc => false,
      :formatter => Log4r::PatternFormatter.new(:pattern => "[%l] %d :: %M")))
  end
  
  # Returns the subdirectory where html_cache files for a particular date are stored
  def cache_subdirectory(date, house)
    date.to_s
  end
  
  # Returns true if any pages on the given date are at "proof" stage which means they might not be finalised
  def has_subpages_in_proof?(date, house)
    each_page_on_date(date, house) do |page|
      return true if page.in_proof?
    end
    false
  end

  def each_page_on_date(date, house)
    url = "http://parlinfoweb.aph.gov.au/piweb/browse.aspx?path=Chamber%20%3E%20#{house.representatives? ? "House" : "Senate"}%20Hansard%20%3E%20#{date.year}%20%3E%20#{date.day}%20#{Date::MONTHNAMES[date.month]}%20#{date.year}"

    # Required to workaround long viewstates generated by .NET (whatever that means)
    # See http://code.whytheluckystiff.net/hpricot/ticket/13
    Hpricot.buffer_size = 1600000

    agent = MechanizeProxy.new
    agent.cache_subdirectory = cache_subdirectory(date, house)

    begin
      page = agent.get(url)
      # HACK: Don't know why if the page isn't found a return code isn't returned. So, hacking around this.
      if page.title == "ParlInfo Web - Error"
        throw "ParlInfo Web - Error"
      end
    rescue
      logger.warn "Could not retrieve overview page for date #{date}"
      return
    end
    # Structure of the page is such that we are only interested in some of the links
    page.links[30..-4].each do |link|
      begin
        page = HansardPage.new(agent.click(link), link, logger)
        yield page
      rescue
        logger.error "Exception thrown during processing of sub page: #{page.permanent_url}"
        raise $!
      end
    end
  end
  
  # Parse but only if there is a page that is at "proof" stage
  def parse_date_house_only_in_proof(date, xml_filename, house)
    if has_subpages_in_proof?(date, house)
      logger.info "Deleting all cached html for #{date} because at least one sub page is in proof stage."
      FileUtils.rm_rf("#{@conf.html_cache_path}/#{cache_subdirectory(date, house)}")
      logger.info "Redownloading pages on #{date}..."
      parse_date_house(date, xml_filename, house)
    end
  end
  
  def parse_date_house(date, xml_filename, house)
    @logger.info "Parsing #{house} speeches for #{date.strftime('%a %d %b %Y')}..."    
    debates = Debates.new(date, house, @logger)
    
    content = false
    each_page_on_date(date, house) do |page|
      content = true
      logger.warn "Page #{page.permanent_url} is in proof stage" if page.in_proof?
      throw "Unsupported: #{page.link}" unless page.supported? || page.to_skip? || page.not_yet_supported?
      if page.supported?
        debates.add_heading(page.hansard_title, page.hansard_subtitle, page.permanent_url)
        speaker = nil
        page.speech_blocks.each do |e|
          speakername, aph_id, interjection, clean_speech = page.parse_speech_block2(e, house)

          # Only change speaker if a speaker name or url was found
          this_speaker = (speakername || aph_id) ? lookup_speaker(page, speakername, aph_id, date, house) : speaker
          # With interjections the next speech should never be by the person doing the interjection
          speaker = this_speaker unless interjection

          debates.add_speech(this_speaker, page.time, page.permanent_url, clean_speech)
          debates.increment_minor_count
        end
      end
      # This ensures that every sub day page has a different major count which limits the impact
      # of when we start supporting things like written questions, procedurial text, etc..
      debates.increment_major_count      
    end
  
    # Only output the debate file if there's going to be something in it
    debates.output(xml_filename) if content
  end
  
  def lookup_speaker_by_title(page, speakername, date, house)
    # Some sanity checking.
    if speakername =~ /speaker/i && house.senate?
      logger.error "The Speaker is not expected in the Senate on #{page.permanent_url}"
      return nil
    elsif speakername =~ /president/i && house.representatives?
      logger.error "The President is not expected in the House of Representatives on #{page.permanent_url}"
      return nil
    elsif speakername =~ /chairman/i && house.representatives?
      logger.error "The Chairman is not expected in the House of Representatives on #{page.permanent_url}"
      return nil
    end
    
    # Handle speakers where they are referred to by position rather than name
    if speakername =~ /^the speaker/i
      @people.house_speaker(date)
    elsif speakername =~ /^the deputy speaker/i
      @people.deputy_house_speaker(date)
    elsif speakername =~ /^the president/i
      @people.senate_president(date)
    elsif speakername =~ /^(the )?chairman/i || speakername =~ /^the deputy president/i
      # The "Chairman" in the main Senate Hansard is when the Senate is sitting as a committee of the whole Senate.
      # In this case, the "Chairman" is the deputy president. See http://www.aph.gov.au/senate/pubs/briefs/brief06.htm#3
      @people.deputy_senate_president(date)
    # Handle names in brackets
    elsif speakername =~ /^the (deputy speaker|acting deputy president|temporary chairman) \((.*)\)/i
      @people.find_member_by_name_current_on_date(Name.title_first_last($~[2]), date, house)
    end
  end
  
  def is_speaker?(speakertitle, date, house)
    lookup_speaker_by_title(page, speakertitle, date, house)
  end
  
  def lookup_speaker_by_name(page, speakername, date, house)
    throw "speakername can not be nil in lookup_speaker" if speakername.nil?
    
    member = lookup_speaker_by_title(page, speakername, date, house)    
    # If member hasn't already been set then lookup using speakername
    if member.nil?
      name = Name.title_first_last(speakername)
      member = @people.find_member_by_name_current_on_date(name, date, house)
    end
    member
  end
  
  def lookup_speaker_by_aph_id(page, aph_id, date, house)
    person = @people.find_person_by_aph_id(aph_id)
    if person
      # Now find the member for that person who is current on the given date
      @people.find_member_by_name_current_on_date(person.name, date, house)
    else
      logger.error "Can't figure out which person the aph id #{aph_id} belongs to on #{page.permanent_url}"
      nil
    end
  end
  
  def lookup_speaker(page, speakername, aph_id, date, house)
    member = lookup_speaker_by_name(page, speakername, date, house)
    if member.nil?
      # Only try to use the aph id if we can't look up by name
      member = lookup_speaker_by_aph_id(page, aph_id, date, house) if aph_id
      if member
        # If link is valid use that to look up the member
        logger.error "Determined speaker #{member.person.name.full_name} by link only on #{page.permanent_url}. Valid name missing."
      end
    end
    
    if member.nil?
      logger.warn "Unknown speaker #{speakername} in #{page.permanent_url}" unless page.generic_speaker?(speakername, house)
      member = UnknownSpeaker.new(speakername)
    end
    member
  end
end

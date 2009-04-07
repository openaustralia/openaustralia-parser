require 'environment'
require 'speech'
require 'mechanize_proxy'
require 'configuration'
require 'debates'
require 'builder_alpha_attributes'
require 'house'
require 'people_image_downloader'
# Using Active Support (part of Ruby on Rails) for Unicode support
require 'activesupport'
require 'log4r'
require 'hansard_day'
require 'patch'

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

class HansardParser
  attr_reader :logger
  
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
  
  # Returns the XML file loaded from aph.gov.au as plain text which contains all the Hansard data
  # Returns nil if it doesn't exist
  def hansard_xml_source_data_on_date(date, house)
    agent = MechanizeProxy.new
    agent.cache_subdirectory = cache_subdirectory(date, house)

    # This is the page returned by Parlinfo Search for that day
    url = "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:chamber/hansard#{house.representatives? ? "r" : "s"}/#{date}/0000"
    page = agent.get(url)
    tag = page.at('div#content center')
    if tag && tag.inner_html =~ /^Unable to find document/
      nil
    else
      link = page.link_with(:text => "View/Save XML")
      if link.nil?
        @logger.error "Link to XML download is missing"
        nil
      else
        text = agent.click(link).body
        # Now check whether there is a patch for that day and if so apply it
        patch_file_path = "#{File.dirname(__FILE__)}/../data/patches/#{house}.#{date}.xml.patch"
        if File.exists?(patch_file_path)
          puts "Using patch file: #{patch_file_path}"
          Patch::patch(text, File.read(patch_file_path))
        else
          text
        end
      end
    end
  end
    
  # Returns HansardDate object for a particular day
  def hansard_day_on_date(date, house)
    text = hansard_xml_source_data_on_date(date, house)
    HansardDay.new(Hpricot.XML(text), @logger) if text
  end
  
  # Parse but only if there is a page that is at "proof" stage
  def parse_date_house_only_in_proof(date, xml_filename, house)
    day = hansard_day_on_date(date, house)
    if day && day.in_proof?
      logger.info "Deleting all cached html for #{date} because that date is in proof stage."
      FileUtils.rm_rf("#{@conf.html_cache_path}/#{cache_subdirectory(date, house)}")
      logger.info "Redownloading pages on #{date}..."
      parse_date_house(date, xml_filename, house)
    end
  end
  
  def parse_date_house(date, xml_filename, house)
    debates = Debates.new(date, house, @logger)
    
    content = false
    day = hansard_day_on_date(date, house)
    if day
      @logger.info "Parsing #{house} speeches for #{date.strftime('%a %d %b %Y')}..."    
      @logger.warn "In proof stage" if day.in_proof?
      day.pages.each do |page|
        content = true
        if page
          if page.is_a?(Array)
            speaker = nil
            page.each do |speech|
              if speech
                debates.add_heading(speech.title, speech.subtitle, day.permanent_url)
                # Only change speaker if a speaker name or url was found
                this_speaker = (speech.speakername || speech.aph_id) ? lookup_speaker(speech, date, house) : speaker
                # With interjections the next speech should never be by the person doing the interjection
                speaker = this_speaker unless speech.interjection
        
                debates.add_speech(this_speaker, speech.time, speech.permanent_url, speech.clean_content)
              end
              debates.increment_minor_count
            end
          elsif page.is_a?(HansardDivision)
            # Lookup names
            yes = page.yes.map do |text|
              name = Name.last_title_first(text)
              member = @people.find_member_by_name_current_on_date(name, date, house)
              throw "Couldn't figure out who #{text} is in division" if member.nil?
              member
            end
            no = page.no.map do |text|
              name = Name.last_title_first(text)
              member = @people.find_member_by_name_current_on_date(name, date, house)
              throw "Couldn't figure out who #{text} is in division" if member.nil?
              member
            end
            yes_tellers = page.yes_tellers.map do |text|
              name = Name.last_title_first(text)
              member = @people.find_member_by_name_current_on_date(name, date, house)
              throw "Couldn't figure out who #{text} is in division" if member.nil?
              member
            end
            no_tellers = page.no_tellers.map do |text|
              name = Name.last_title_first(text)
              member = @people.find_member_by_name_current_on_date(name, date, house)
              throw "Couldn't figure out who #{text} is in division" if member.nil?
              member
            end
            debates.add_division(yes, no, yes_tellers, no_tellers, page.time, page.permanent_url)
          end
        end
        # This ensures that every sub day page has a different major count which limits the impact
        # of when we start supporting things like written questions, procedurial text, etc..
        debates.increment_major_count      
      end
    else
      @logger.info "Skipping #{house} speeches for #{date.strftime('%a %d %b %Y')} (no data available)"
    end
  
    # Only output the debate file if there's going to be something in it
    debates.output(xml_filename) if content
  end
  
  def lookup_speaker_by_title(speech, date, house)
    # Some sanity checking.
    if speech.speakername =~ /speaker/i && house.senate?
      logger.error "The Speaker is not expected in the Senate"
      return nil
    elsif speech.speakername =~ /president/i && house.representatives?
      logger.error "The President is not expected in the House of Representatives"
      return nil
    elsif speech.speakername =~ /chairman/i && house.representatives?
      logger.error "The Chairman is not expected in the House of Representatives"
      return nil
    end
    
    # Handle speakers where they are referred to by position rather than name
    # Handle names in brackets first
    if speech.speakername =~ /^(.*) \(the (deputy speaker|acting deputy president|temporary chairman)\)/i
      @people.find_member_by_name_current_on_date(Name.last_title_first($~[1]), date, house)
    elsif speech.speakername =~ /^the speaker/i
      @people.house_speaker(date)
    elsif speech.speakername =~ /^the deputy speaker/i
      @people.deputy_house_speaker(date)
    elsif speech.speakername =~ /^the president/i
      @people.senate_president(date)
    elsif speech.speakername =~ /^(the )?chairman/i || speech.speakername =~ /^the deputy president/i
      # The "Chairman" in the main Senate Hansard is when the Senate is sitting as a committee of the whole Senate.
      # In this case, the "Chairman" is the deputy president. See http://www.aph.gov.au/senate/pubs/briefs/brief06.htm#3
      @people.deputy_senate_president(date)
    end
  end
  
  def lookup_speaker_by_name(speech, date, house)
    #puts "Looking up speaker by name: #{speech.speakername}"
    throw "speakername can not be nil in lookup_speaker" if speech.speakername.nil?
    
    member = lookup_speaker_by_title(speech, date, house)    
    # If member hasn't already been set then lookup using speakername
    if member.nil?
      name = Name.title_first_last(speech.speakername)
      member = @people.find_member_by_name_current_on_date(name, date, house)
      if member.nil?
        name = Name.last_title_first(speech.speakername)
        member = @people.find_member_by_name_current_on_date(name, date, house)
      end
    end
    member
  end
  
  def lookup_speaker_by_aph_id(speech, date, house)
    # The aph_id "10000" is special. It represents the speaker, deputy speaker, something like that.
    # It could be anyone of a number of poeple. So, if it is that, just ignore it.
    if speech.aph_id && speech.aph_id != "10000"
      person = @people.find_person_by_aph_id(speech.aph_id)
      if person
        person.position_current_on_date(date, house)
      else
        logger.error "Can't figure out which person the aph id #{speech.aph_id} belongs to"
        nil
      end
    end
  end
  
  def lookup_speaker(speech, date, house)
    # First try looking up speaker by id then try name
    member = lookup_speaker_by_aph_id(speech, date, house) || lookup_speaker_by_name(speech, date, house)
    
    if member.nil?
      logger.warn "Unknown speaker #{speech.speakername}" unless HansardSpeech.generic_speaker?(speech.speakername)
      member = UnknownSpeaker.new(speech.speakername)
    end
    member
  end
end

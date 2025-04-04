# frozen_string_literal: true

require "speech"
require "mechanize"
require "configuration"
require "debates"
require "builder_alpha_attributes"
require "house"
require "people_image_downloader"
require "log4r"
require "hansard_day"
require "hansard_rewriter"
require "patch"

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
    @logger = Log4r::Logger.new "HansardParser"
    # Log to both standard out and the file set in configuration.yml
    o1 = Log4r::Outputter.stdout
    # Only log error messages or above to standard output
    o1.level = Log4r::ERROR
    @logger.add(o1)
    @logger.add(Log4r::FileOutputter.new("foo", filename: @conf.log_path, trunc: false,
                                                formatter: Log4r::PatternFormatter.new(pattern: "[%l] %d :: %M")))

    @rewriter = HansardRewriter.new(@logger)
  end

  # Returns the XML file loaded from aph.gov.au as plain text which contains all the Hansard data
  # Returns nil it it doesn't exist
  # This is the original data without any patches applied at this end
  def unpatched_hansard_xml_source_data_on_date(date, house)
    agent = Mechanize.new
    # We've been kindly given a special user agent to use so
    # that our traffic isn't blocked by the application firewall
    # of aph.gov.au.
    # See https://mail.missiveapp.com/#search/aph.gov.au/conversations/4f0a0161-421e-4d0b-9dd1-49275353acf7/messages/bc27bcd1-2cba-5e63-64d3-a364037629a2
    agent.user_agent = "Mozilla/5.0+AppleWebKit/537.36+(KHTML,+like+Gecko;+compatible;+Amazonbot/0.1;++https://developer.amazon.com/support/amazonbot)+Chrome/119.0.6045.214+Safari/537.36"

    # This is the page returned by Parlinfo Search for that day
    url = "https://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;adv=yes;orderBy=_fragment_number,doc_date-rev;page=0;query=Dataset%3Ahansard#{house.representatives? ? 'r' : 's'},hansard#{house.representatives? ? 'r' : 's'}80%20Date%3A#{date.day}%2F#{date.month}%2F#{date.year};rec=0;resCount=Default"
    page = agent.get(url)

    tag = page.at("div#content center")
    if tag && tag.inner_html =~ /^Unable to find document/
      nil
    else
      link = page.link_with(text: "View/Save XML")
      if link.nil?
        @logger.warn "#{date} #{house}: Link to XML download is missing"
        nil
      else
        agent.click(link).body
      end
    end
  end

  # Returns the XML file loaded from aph.gov.au as plain text which contains all the Hansard data
  # Returns nil if it doesn't exist
  def hansard_xml_source_data_on_date(date, house)
    text = unpatched_hansard_xml_source_data_on_date(date, house)
    return unless text

    # Horribe hack to fix some stupid wrapping
    text = text.gsub(/\r/, "")
    text = text.gsub(%r{</span>[^<]*<span style="&#xD;&#xA;    font-size:9.5pt;&#xD;&#xA;  ">}m, "")

    # Now check whether there is a patch for that day and if so apply it
    patch_file_path = "#{File.dirname(__FILE__)}/../data/patches/#{house}.#{date}.xml.patch"
    if File.exist?(patch_file_path)
      begin
        Patch.patch(text, File.read(patch_file_path))
      rescue StandardError
        # Reraising error so that we can include a little more info
        raise "#{date} #{house}: Patch failed"
      end
    else
      text
    end
  end

  def house_directory_name(house)
    if house == House.representatives
      "representatives_debates"
    elsif house == House.senate
      "senate_debates"
    else
      raise "Assertion failed! unknown house!"
    end
  end

  def origxml_filename(date, house)
    "#{@conf.xml_path}/origxml/#{house_directory_name(house)}/#{date}.xml"
  end

  def rewritexml_filename(date, house)
    "#{@conf.xml_path}/rewritexml/#{house_directory_name(house)}/#{date}.xml"
  end

  # Returns HansardDate object for a particular day
  def hansard_day_on_date(date, house)
    # Use the origxml as a cache if it exists. Otherwise fetch
    # it via the web from aph
    filename = origxml_filename(date, house)
    if File.exist?(filename)
      puts "Reading cached xml from #{filename}..."
      xml = File.read(filename)
      # An empty file signifies there is no data for this day
      xml = nil if xml == ""
    else
      # Load the XML data
      xml = hansard_xml_source_data_on_date(date, house)
      # And cache it
      File.open(filename, "w") do |f|
        # If there is no data for this day (parliament didn't sit) then
        # still create a file but leave it empty. This allows to
        # cache that fact without having to rerequest things from the aph
        # site
        f.write(xml.to_s) if xml
      end
    end
    return unless xml

    # APH changed their XML format on the 10th of May 2011
    if date >= Date.new(2011, 5, 10)
      # Rewrite the XML data back to a sane format
      new_xml = @rewriter.rewrite_xml Hpricot.XML(xml)

      # Save the rewritten XML data
      File.open(rewritexml_filename(date, house), "w") { |f| f.write(new_xml.to_s) }

      # Process the day
      HansardDay.new(new_xml, @logger)
    else
      HansardDay.new(Hpricot.XML(xml), @logger)
    end
  end

  # Parse but only if there is a page that is at "proof" stage
  def parse_date_house_only_in_proof(date, xml_filename, house)
    day = hansard_day_on_date(date, house)
    return unless day&.in_proof?

    logger.info "Deleting cached origxml file for #{date} because that date is in proof stage."
    FileUtils.rm_f(origxml_filename(date, house))
    logger.info "Redownloading pages on #{date}..."
    parse_date_house(date, xml_filename, house)
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

        case page
        when HansardUnsupported
          # Adding header as soon as possible (even for unsupported sections), so that as new bits of the Han
          # become supported we don't change the id's of the headings.
          debates.add_heading(page.title, page.subtitle, page.permanent_url, nil)
          # Do nothing
        when Array
          unless page.empty?
            debates.add_heading(page.first.title, page.first.subtitle, day.permanent_url,
                                page.first.bills)
          end
          speaker = nil
          page.each do |speech|
            if speech
              # Only change speaker if a speaker name or url was found
              this_speaker = speech.speakername || speech.aph_id ? lookup_speaker(speech, date, house) : speaker
              # With interjections the next speech should never be by the person doing the interjection
              speaker = this_speaker unless speech.interjection

              debates.add_speech(this_speaker, speech.time, speech.permanent_url, speech.clean_content,
                                 interjection: speech.interjection, continuation: speech.continuation)
            end
            debates.increment_minor_count
          end
        when HansardDivision
          puts "#{date} #{house} #{page.title} #{page.subtitle}"
          debates.add_heading(page.title, page.subtitle, page.permanent_url, page.bills)
          # Lookup names
          yes = page.yes.map do |text|
            next if text.empty?

            name = Name.last_title_first(text)
            member = @people.find_member_by_name_current_on_date(name, date, house)
            raise "#{date} #{house}: Couldn't figure out who #{text} is in division (voting yes)" if member.nil?

            member
          end.compact
          no = page.no.map do |text|
            next if text.empty?

            name = Name.last_title_first(text)
            member = @people.find_member_by_name_current_on_date(name, date, house)
            raise "#{date} #{house}: Couldn't figure out who #{text} is in division (voting no)" if member.nil?

            member
          end.compact
          yes_tellers = page.yes_tellers.map do |text|
            next if text.empty?

            name = Name.last_title_first(text)
            member = @people.find_member_by_name_current_on_date(name, date, house)
            raise "#{date} #{house}: Couldn't figure out who #{text} is in division (voting yes and teller)" if member.nil?

            member
          end.compact
          no_tellers = page.no_tellers.map do |text|
            next if text.empty?

            name = Name.last_title_first(text)
            member = @people.find_member_by_name_current_on_date(name, date, house)
            raise "#{date} #{house}: Couldn't figure out who #{text} is in division (voting no and teller)" if member.nil?

            member
          end.compact
          pairs = page.pairs.map do |pair|
            pair.map do |text|
              next if text.empty?

              name = Name.last_title_first(text)
              member = @people.find_member_by_name_current_on_date(name, date, house)
              raise "#{date} #{house}: Couldn't figure out who #{text} is in division (in a pair)" if member.nil?

              member
            end.compact
          end.compact
          debates.add_division(yes_members: yes, no_members: no, yes_tellers: yes_tellers, no_tellers: no_tellers,
                               pairs: pairs, time: page.time, url: page.permanent_url, bills: page.bills)
        end
        # This ensures that every sub day page has a different major count which limits the impact
        # of when we start supporting things like written questions, procedurial text, etc..
        debates.increment_major_count
      end
    else
      @logger.info "Skipping #{house} speeches for #{date.strftime('%a %d %b %Y')} (no data available)"
    end

    # Calculate speech durations once all sections have been added
    debates.calculate_speech_durations

    # Only output the debate file if there's going to be something in it
    debates.output(xml_filename) if content
  end

  def lookup_speaker_by_title(speech, date, house)
    # Some sanity checking.
    if speech.speakername =~ /speaker/i && house.senate?
      logger.error "#{date} #{house}: The Speaker is not expected in the Senate"
      return nil
    elsif speech.speakername =~ /president/i && house.representatives?
      logger.error "#{date} #{house}: The President is not expected in the House of Representatives"
      return nil
    elsif speech.speakername =~ /chairman/i && house.representatives?
      logger.error "#{date} #{house}: The Chairman is not expected in the House of Representatives"
      return nil
    end

    # Handle speakers where they are referred to by position rather than name
    # Handle names in brackets first
    case speech.speakername
    when /^(.*) \(the (deputy speaker|acting deputy president|temporary chairman)\)/i
      @people.find_member_by_name_current_on_date(Name.last_title_first($LAST_MATCH_INFO[1]), date, house)
    when /^the (deputy speaker|acting deputy president|temporary chairman) \((.*)\)/i
      @people.find_member_by_name_current_on_date(Name.title_first_last($LAST_MATCH_INFO[2]), date, house)
    when /^the speaker/i
      @people.house_speaker(date)
    when /^the deputy speaker/i
      @people.deputy_house_speaker(date)
    when /^the president/i
      @people.senate_president(date)
    when /^(the )?chairman/i, /^the deputy president/i
      # The "Chairman" in the main Senate Hansard is when the Senate is sitting as a committee of the whole Senate.
      # In this case, the "Chairman" is the deputy president. See http://www.aph.gov.au/senate/pubs/briefs/brief06.htm#3
      @people.deputy_senate_president(date)
    end
  end

  def lookup_speaker_by_name(speech, date, house)
    # puts "Looking up speaker by name: #{speech.speakername}"
    raise "speakername can not be nil in lookup_speaker" if speech.speakername.nil?

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
    # Annoyingly, "1000" keeps getting used as well to mean the same thing. This is clearly a mistake, so
    # we'll ignore it in the same way
    aph_id = speech.aph_id.upcase unless speech.aph_id.nil?
    return unless aph_id && aph_id != "10000" && aph_id != "1000"

    person = @people.find_person_by_aph_id(aph_id)
    if person
      period = person.position_current_on_date(date, house)
      logger.error "#{date} #{house}: Found person (#{person.name.full_name}) but not both in the right period and house. Strange..." if period.nil?
      period
    else
      logger.error "#{date} #{house}: Can't figure out which person the aph id #{speech.aph_id} belongs to"
      nil
    end
  end

  def lookup_speaker(speech, date, house)
    # First try looking up speaker by id then try name
    member = lookup_speaker_by_aph_id(speech, date, house) || lookup_speaker_by_name(speech, date, house)

    if member.nil?
      unless HansardSpeech.generic_speaker?(speech.speakername)
        # It is so common that the problem with "The Temporary Chairman" occurs (where there real name is not included)
        # that we're going to downgrade this to a warning so that it doesn't drown out other problems
        if ["The ACTING DEPUTY PRESIDENT", "The TEMPORARY CHAIRMAN", "TEMPORARY CHAIRMAN, The", "The ACTING SPEAKER",
            "The Clerk", "The ACTING PRESIDENT", "DEPUTY SPEAKER, The", "DEPUTY CHAIR"].include?(speech.speakername)
          logger.warn "#{date} #{house} #{speech.aph_id}: Unknown speaker #{speech.speakername}"
        else
          logger.error "#{date} #{house} #{speech.aph_id}: Unknown speaker #{speech.speakername}"
        end
      end
      member = UnknownSpeaker.new(speech.speakername)
    end
    member
  end
end

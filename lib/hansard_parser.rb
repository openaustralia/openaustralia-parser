# frozen_string_literal: true

require "log4r"

require_relative "aph_mechanize_agent"
require_relative "speech"
require_relative "configuration"
require_relative "debates"
require_relative "builder_alpha_attributes"
require_relative "house"
require_relative "people_image_downloader"
require_relative "hansard_day"
require_relative "hansard_rewriter"
require_relative "patch"

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
  attr_reader :logger, :output_dir, :log_path, :xml_path

  def initialize(people, output_dir: nil)
    @people = people
    @conf = Configuration.new

    @output_dir = output_dir
    @log_path = output_dir ? "#{output_dir}/parser.log" : @conf.log_path
    @xml_path = output_dir ? "#{output_dir}/" : @conf.xml_path

    # Set up logging
    @logger = Log4r::Logger.new "HansardParser"
    # Log to both standard out and the file set in configuration.yml
    o1 = Log4r::Outputter.stdout
    # Only log error messages or above to standard output
    o1.level = Log4r::ERROR
    @logger.add(o1)
    @logger.add(Log4r::FileOutputter.new("foo", filename: log_path, trunc: false,
                                         formatter: Log4r::PatternFormatter.new(pattern: "[%l] %d :: %M")))

    @rewriter = HansardRewriter.new(@logger)
  end

  # Returns the XML file loaded from aph.gov.au as plain text which contains all the Hansard data
  # Returns nil it it doesn't exist
  # This is the original data without any patches applied at this end
  def unpatched_hansard_xml_source_data_on_date(date, house)
    agent = AphMechanizeAgent.new_agent

    # This is the page returned by Parlinfo Search for that day
    url = "https://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;adv=yes;orderBy=_fragment_number,doc_date-rev;page=0;query=Dataset%3Ahansard#{house.representatives? ? 'r' : 's'},hansard#{house.representatives? ? 'r' : 's'}80%20Date%3A#{date.day}%2F#{date.month}%2F#{date.year};rec=0;resCount=Default"
    page = AphMechanizeAgent.with_backoff { agent.get(url) }

    tag = page.at("div#content center")
    if tag && tag.inner_html =~ /^Unable to find document/
      nil
    else
      link = page.link_with(text: "View/Save XML")
      if link.nil?
        @logger.warn "#{date} #{house}: Link to XML download is missing"
        nil
      else
        AphMechanizeAgent.with_backoff { agent.click(link).body }
      end
    end
  end

  # Returns the XML file loaded from aph.gov.au as plain text which contains all the Hansard data
  # Returns nil if it doesn't exist
  def hansard_xml_source_data_on_date(date, house)
    text = unpatched_hansard_xml_source_data_on_date(date, house)
    return unless text

    # Mechanize's #body returns the response tagged ASCII-8BIT regardless of the actual
    # (UTF-8) content, and that mistagging survives through every downstream
    # inner_text/inner_html/string interpolation step, contributing to inconsistent
    # entity encoding later in the pipeline (eg &mdash; turning up where a literal char
    # or numeric ref was expected - see the xml_safe_html fixes in HansardRewriter and
    # HansardSpeech.clean_content_any). Fix the tag at the source.
    text = text.force_encoding("UTF-8")

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
    "#{xml_path}/origxml/#{house_directory_name(house)}/#{date}.xml"
  end

  def rewritexml_filename(date, house)
    "#{xml_path}/rewritexml/#{house_directory_name(house)}/#{date}.xml"
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
      FileUtils.mkdir_p(File.dirname(filename))
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
      new_xml = @rewriter.rewrite_xml Nokogiri::XML(xml)

      filename = rewritexml_filename(date, house)
      FileUtils.mkdir_p(File.dirname(filename))
      # Save the rewritten XML data
      File.open(filename, "w") { |f| f.write(new_xml.to_s) }

      # Process the day
      HansardDay.new(new_xml, @logger)
    else
      HansardDay.new(Nokogiri::XML(xml), @logger)
    end
  end

  PROOF_TAG = %r{<proof>\s*1\s*</proof>}
  FINAL_TAG = %r{<proof>\s*0\s*</proof>}
  DEBATES_TAG = /<debates\b[^>]*>/

  # The alert mailer skips anything dated more than 8 weeks ago (AlertMaxAge::MAX_AGE in twfy), so loading a day
  # that is older than that again cannot email anyone. One more week covers the time between a run and the next
  # mailer run. Days newer than this are never picked, whatever the mode.
  ALERT_SAFE_AFTER_DAYS = 9 * 7

  # The [date, house] pairs whose cached origxml is at proof stage, up to limit, in the order of #outward_from
  # around, and only those old enough to load again without emailing anyone. Reads only the local cache, so it
  # never calls aph.
  def proof_days(limit:, around:, today: Date.today)
    days = cached_origxml_days(today: today).select { |_date, _house, filename| File.read(filename).match?(PROOF_TAG) }
    outward_from(days, around, limit)
  end

  # The [date, house] pairs we cannot yet say are proof or final: the cached origxml says which, but the
  # scrapedxml has no proof attribute because the day was parsed before the parser wrote one. Parsing the day
  # again gives it the attribute, and with it the proof column, so the day drops out of this list. Up to limit,
  # in the order of #outward_from around, and only those old enough to load again without emailing anyone. Reads
  # only the local cache.
  def days_without_proof_flag(limit:, around:, today: Date.today)
    days = cached_origxml_days(today: today).select do |date, house, filename|
      text = File.read(filename)
      (text.match?(PROOF_TAG) || text.match?(FINAL_TAG)) && scrapedxml_without_proof_flag?(date, house)
    end
    outward_from(days, around, limit)
  end

  # true or false as the cached origxml says, nil when there is no cached copy or it has no proof value.
  def cached_proof(date, house)
    filename = origxml_filename(date, house)
    return unless File.size?(filename)

    text = File.read(filename)
    return true if text.match?(PROOF_TAG)

    false if text.match?(FINAL_TAG)
  end

  # Every cached [date, house, filename] old enough to load again without emailing anyone (see ALERT_SAFE_AFTER_DAYS).
  def cached_origxml_days(today: Date.today)
    cutoff = today - ALERT_SAFE_AFTER_DAYS
    [House.representatives, House.senate].flat_map do |house|
      Dir["#{xml_path}/origxml/#{house_directory_name(house)}/*.xml"].filter_map do |filename|
        date = Date.iso8601(File.basename(filename, ".xml"))
        [date, house, filename] if date < cutoff
      end
    end
  end

  # False when there is no scrapedxml for the day (it has not been parsed, which is a different problem).
  def scrapedxml_without_proof_flag?(date, house)
    filename = "#{xml_path}/scrapedxml/#{house_directory_name(house)}/#{date}.xml"
    return false unless File.size?(filename)

    tag = File.read(filename, 2000)[DEBATES_TAG]
    !tag.nil? && !tag.include?("proof=")
  end

  # Picks up to limit days by working outward from the pivot date, alternating between the nearest day on or
  # after it and the nearest day before it, so each run reaches toward today and toward the past together. When
  # one side runs out, the rest come from the other. On the same date the Representatives come before the Senate.
  def outward_from(days, pivot, limit)
    newer, older = days.partition { |date, _house, _filename| date >= pivot }
    newer = newer.sort_by { |date, house, _filename| [date.jd, house_order(house)] }
    older = older.sort_by { |date, house, _filename| [-date.jd, house_order(house)] }

    picked = []
    while picked.size < limit && (newer.any? || older.any?)
      picked << newer.shift if newer.any?
      picked << older.shift if older.any? && picked.size < limit
    end
    picked.map { |date, house, _filename| [date, house] }
  end

  def house_order(house)
    house.representatives? ? 0 : 1
  end

  # Parse but only if there is a page that is at "proof" stage. A proof day gets a fresh copy from aph first
  # (see refresh_origxml), unless this run has just fetched it.
  def parse_date_house_only_in_proof(date, xml_filename, house)
    just_fetched = !File.exist?(origxml_filename(date, house))
    day = hansard_day_on_date(date, house)
    return unless day&.in_proof?

    refresh_origxml(date, house) unless just_fetched
    parse_date_house(date, xml_filename, house)
  end

  # Downloads a fresh copy of a day and puts it in place as origxml only if it is valid and has changed.
  # Returns :replaced, :unchanged or :kept (no usable fresh copy). Any failure leaves the cached copy untouched.
  def refresh_origxml(date, house)
    filename = origxml_filename(date, house)
    fresh = download_valid_xml(date, house)
    return :kept unless fresh

    if File.read(filename) == fresh
      logger.info "#{date} #{house}: The fresh copy is the same as the cached origxml"
      return :unchanged
    end

    temporary = "#{filename}.new"
    begin
      File.write(temporary, fresh)
      File.rename(temporary, filename)
    ensure
      FileUtils.rm_f(temporary)
    end
    logger.info "#{date} #{house}: Replaced the cached origxml with a fresh copy"
    :replaced
  end

  # Returns the fresh text, or nil (after logging why) when there is nothing usable to replace the cache with.
  def download_valid_xml(date, house)
    text = hansard_xml_source_data_on_date(date, house)
    unless text
      logger.warn "#{date} #{house}: No fresh copy is available from aph, keeping the cached origxml"
      return
    end

    problem = problem_with_fresh_xml(text, date)
    if problem
      logger.warn "#{date} #{house}: Not using the fresh copy because #{problem}, keeping the cached origxml"
      return
    end

    text
  rescue StandardError => e
    @aph_blocked = true if aph_is_refusing_requests?(e)
    logger.error "#{date} #{house}: Could not download a fresh copy (#{e.class}: #{e.message}), keeping the cached origxml"
    nil
  end

  # True once aph has refused a download with a rate limit response (AphMechanizeAgent.with_backoff has already
  # retried and given up). A caller working through many days should stop and try again later.
  def aph_blocked?
    @aph_blocked == true
  end

  def aph_is_refusing_requests?(error)
    error.is_a?(Mechanize::ResponseCodeError) && AphMechanizeAgent::RATE_LIMIT_RESPONSE_CODES.include?(error.response_code)
  end

  def problem_with_fresh_xml(text, date)
    root = Nokogiri::XML(text).root
    return "it is not a hansard document" unless root&.name == "hansard"

    found = root.at_xpath("session.header/date")&.text&.strip
    "it is for #{found}, not #{date}" if found && found != date.to_s
  end

  def parse_date_house(date, xml_filename, house)
    debates = Debates.new(date, house, @logger)

    content = false
    day = hansard_day_on_date(date, house)
    if day
      @logger.info "Parsing #{house} speeches for #{date.strftime('%a %d %b %Y')}..."
      @logger.warn "In proof stage" if day.in_proof?
      debates.proof = day.proof
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
              this_speaker = if speech.speakername || speech.aph_id
                               lookup_speaker(speech, date,
                                              house)
                             else
                               speaker
                             end
              # With interjections the next speech should never be by the person doing the interjection
              speaker = this_speaker unless speech.interjection

              debates.add_speech(this_speaker, speech.time, speech.permanent_url, speech.clean_content,
                                 interjection: speech.interjection, continuation: speech.continuation)
            end
            debates.increment_minor_count
          end
        when HansardDivision
          puts "#{date} #{house} #{page.title} #{page.subtitle}#{' (proof-only)' if day.in_proof?}"
          debates.add_heading(page.title, page.subtitle, page.permanent_url, page.bills)
          # Lookup names
          yes = page.yes.map do |text|
            next if text.empty?

            name = Name.last_title_first(text)
            member = @people.find_member_by_name_current_on_date(name, date, house)
            if member.nil?
              extra_details = unmatched_name_details(name, house)
              raise "#{date} #{house}: Couldn't figure out who #{text} is in division (voting yes) #{name.to_h.inspect} #{extra_details}"
            end

            member
          end.compact
          no = page.no.map do |text|
            next if text.empty?

            name = Name.last_title_first(text)
            member = @people.find_member_by_name_current_on_date(name, date, house)
            if member.nil?
              extra_details = unmatched_name_details(name, house)
              raise "#{date} #{house}: Couldn't figure out who #{text} is in division (voting no) #{name.to_h.inspect} #{extra_details}"
            end

            member
          end.compact
          yes_tellers = page.yes_tellers.map do |text|
            next if text.empty?

            name = Name.last_title_first(text)
            member = @people.find_member_by_name_current_on_date(name, date, house)
            if member.nil?
              extra_details = unmatched_name_details(name, house)
              raise "#{date} #{house}: Couldn't figure out who #{text} is in division (voting yes and teller) #{name.to_h.inspect} #{extra_details}"
            end

            member
          end.compact
          no_tellers = page.no_tellers.map do |text|
            next if text.empty?

            name = Name.last_title_first(text)
            member = @people.find_member_by_name_current_on_date(name, date, house)
            if member.nil?
              extra_details = unmatched_name_details(name, house)
              raise "#{date} #{house}: Couldn't figure out who #{text} is in division (voting no and teller) #{name.to_h.inspect} #{extra_details}"
            end

            member
          end.compact
          pairs = page.pairs.map do |pair|
            pair.map do |text|
              next if text.empty?

              name = Name.last_title_first(text)
              member = @people.find_member_by_name_current_on_date(name, date, house)
              if member.nil?
                extra_details = unmatched_name_details(name, house)
                raise "#{date} #{house}: Couldn't figure out who #{text} is in division (in a pair) #{name.to_h.inspect} #{extra_details}"
              end

              member
            end.compact
          end.compact
          unpaired = page.unpaired.map do |text|
            name = Name.last_title_first(text)
            member = @people.find_member_by_name_current_on_date(name, date, house)
            if member.nil?
              extra_details = unmatched_name_details(name, house)
              raise "#{date} #{house}: Couldn't figure out who #{text} is in division (unpaired) #{name.to_h.inspect} #{extra_details}"
            end

            member
          end
          @logger.warn "#{date} #{house}: #{page.odd_pairs_message}" if page.odd_pairs?
          debates.add_division(yes_members: yes, no_members: no, yes_tellers: yes_tellers, no_tellers: no_tellers,
                               pairs: pairs, unpaired: unpaired, time: page.time, url: page.permanent_url, bills: page.bills)
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

  # Debug detail for a division name that didn't resolve to a sitting member -
  # every candidate this name could plausibly be, with the IDs (Person#id,
  # aph_id, each Period#id) and house needed to find and fix the actual
  # data/*.csv row. house is the division's own house (Senate/Representatives),
  # included even when no candidate was found at all, and used to flag a
  # found-but-wrong-house candidate explicitly.
  def unmatched_name_details(name, house)
    candidates = @people.find_people_by_name(name)
    return "not found (looking in #{house})" if candidates.nil? || candidates.empty?

    details = candidates.map do |person|
      periods = person.periods.map do |p|
        wrong_house = p.house == house ? "" : ", NOT #{house}"
        "#{p.house}#{wrong_house}: #{p.id} (#{p.from_date} to #{p.to_date})"
      end.join(", ")
      "#{person.id} aph_id=#{person.aph_id.inspect} #{person.name.full_name} [#{periods}]"
    end.join("; ")
    "not sitting in #{house} - #{details}"
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
      @people.find_member_by_name_current_on_date(Name.last_title_first($LAST_MATCH_INFO[1]),
                                                  date, house)
    when /^the (deputy speaker|acting deputy president|temporary chairman) \((.*)\)/i
      @people.find_member_by_name_current_on_date(Name.title_first_last($LAST_MATCH_INFO[2]),
                                                  date, house)
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
    member = lookup_speaker_by_aph_id(speech, date,
                                      house) || lookup_speaker_by_name(speech, date, house)

    if member.nil?
      unless HansardSpeech.generic_speaker?(speech.speakername)
        # It is so common that the problem with "The Temporary Chairman" occurs (where there real name is not included)
        # that we're going to downgrade this to a warning so that it doesn't drown out other problems
        if ["The ACTING DEPUTY PRESIDENT", "The TEMPORARY CHAIRMAN", "TEMPORARY CHAIRMAN, The", "The ACTING SPEAKER",
            "The Clerk", "The ACTING PRESIDENT", "DEPUTY SPEAKER, The", "DEPUTY CHAIR"].include?(speech.speakername)
          logger.warn "#{date} #{house} #{speech.aph_id}: Unknown speaker \"#{speech.speakername}\""
        else
          logger.error "#{date} #{house} #{speech.aph_id}: Unknown speaker \"#{speech.speakername}\""
        end
      end
      member = UnknownSpeaker.new(speech.speakername)
    end
    member
  end
end

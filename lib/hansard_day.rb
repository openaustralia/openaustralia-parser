# frozen_string_literal: true

# vim: set ts=2 sw=2 et sts=2 ai:

require "additions"
require "house"
require "hansard_division"
require "hansard_speech"
require "date"

# Use this for sections of the Hansard that we're not currently supporting. Allows us to track
# title and subtitle.
class HansardUnsupported
  attr_reader :title, :subtitle

  def initialize(title, subtitle, day)
    @title = title
    @subtitle = subtitle
    @day = day
  end

  def permanent_url
    @day.permanent_url
  end
end

class HansardDay
  # On 2011-02-22 there was a tied vote and the speaker didn't need to cast a deciding
  # vote because an absolute majority was required
  ALLOW_TIED_VOTE_DATES = [Date.new(2011, 2, 22)].freeze

  def initialize(page, logger = nil)
    @page = page
    @logger = logger
    @house = nil
    @role_map = {}
  end

  def house
    # Cache value
    @house ||= case @page.at("chamber").inner_text.downcase
               when "senate" then House.senate
               when "reps", "house of reps" then House.representatives
               else raise "Unexpected value for contents '#{@page.at('chamber').inner_text}' of <chamber> tag"
               end
    @house
  end

  def date
    # Cache value
    @date ||= Date.parse(@page.at("date").inner_html)
    @date
  end

  def permanent_url
    "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;adv=yes;orderBy=_fragment_number,doc_date-rev;page=0;query=Dataset%3Ahansard#{house.representatives? ? 'r' : 's'},hansard#{house.representatives? ? 'r' : 's'}80%20Date%3A#{date.day}%2F#{date.month}%2F#{date.year};rec=0;resCount=Default"
  end

  def in_proof?
    proof = @page.at("proof").inner_html
    @logger.error "#{date} #{house}: Unexpected value '#{proof}' inside tag <proof>" unless %w[1 0].include?(proof)
    proof == "1"
  end

  def add_speaker_to_tied_votes?
    house == House.representatives && !ALLOW_TIED_VOTE_DATES.include?(date)
  end

  # Strip any HTML/XML tags from the given text and remove new-line characters
  def strip_tags(text)
    text.gsub(%r{</?[^>]*>}, "").gsub("\r", "").gsub("\n", "")
  end

  # Search for the title tag and return its value, stripping out any HTML tags
  def title_tag_value(debate)
    # Doing this rather than calling inner_text to preserve html entities which for some reason get all screwed up by inner_text
    strip_tags(debate.search("> * > title").map { |e| e.inner_html.strip }.join("; ")).strip
  end

  def title(debate)
    case debate.name
    when "debate", "petition.group"
      title = title_tag_value(debate).strip
      cognates = debate.search("> debateinfo > cognate > cognateinfo > title").map { |a| strip_tags(a.inner_html) }
      ([title] + cognates).join("; ")
    when "subdebate.1", "subdebate.2", "subdebate.3", "subdebate.4"
      title(debate.parent).strip
    else
      raise "Unexpected tag #{debate.name}"
    end
  end

  def bills(debate)
    results = []

    case debate.name
    when "debate", "petition.group"
      # cognate debates can have multiple bill ids
      if debate.at("> debateinfo") && !debate.at("> debateinfo").children_of_type("id.no").empty?
        if debate.at("> debateinfo > type").inner_text.downcase == "bills"
          id = debate.at("/debateinfo").children_of_type("id.no")[0].inner_text
          title = debate.at("> debateinfo > title").inner_text
          url = bill_url(id)
          results << { id: id, title: title, url: url }
        end
        debate.search("> debateinfo > cognate").each do |congnate|
          next if congnate.at(:type).inner_text.downcase != "bills"

          id_elem = congnate.at(:cognateinfo).children_of_type("id.no")[0]
          # some old Hansard duplicates <cognateinfo> with <id.no> missing
          next unless id_elem

          id = id_elem.inner_text
          title = congnate.at(:title).inner_text
          url = bill_url(id)
          results << { id: id, title: title, url: url }
        end
      end
    when "subdebate.1", "subdebate.2", "subdebate.3", "subdebate.4"
      if debate.get_elements_by_tag_name("subdebate.text").empty?
        results = bills(debate.parent)
      else
        unless debate.get_elements_by_tag_name("subdebate.text")[0].get_elements_by_tag_name("a").empty?
          debate.get_elements_by_tag_name("subdebate.text")[0].get_elements_by_tag_name("a").each do |a|
            id = strip_tags(a["href"].strip)
            title = strip_tags(a.inner_text.strip)
            url = bill_url(id)
            results << { id: id, title: title, url: url }
          end
        end
      end
    else
      raise "Unexpected tag #{debate.name}"
    end

    results
  end

  def subtitle(debate)
    case debate.name
    when "debate", "petition.group"
      ""
    when "subdebate.1"
      title_tag_value(debate).strip
    when "subdebate.2", "subdebate.3", "subdebate.4"
      front = ""
      if debate.parent.name == "subdebate.1"
        front = subtitle(debate.parent).strip
      else
        possible_firstdebates = debate.parent.search("(subdebate.1)")
        front = if possible_firstdebates.length == 1
                  subtitle(possible_firstdebates[0]).strip
                else
                  title(debate).strip
                end
      end
      raise "Front title is to short! '#{front}' #{front.length}" if front.empty?

      "#{front}; #{title_tag_value(debate)}".strip
    else
      raise "Unexpected tag #{debate.name}"
    end
  end

  def time(debate)
    # HACK: Hmmm.. check this out more
    tag = debate.at("//(time.stamp)")
    tag&.inner_html
  end

  def pages_from_debate(debate)
    p = []
    title = title(debate)
    subtitle = subtitle(debate)
    bills = bills(debate)

    question = false
    procedural = false

    debate.each_child_node do |e|
      case e.name
      when "debateinfo", "subdebateinfo", "subdebate.text", "petition.groupinfo"
        question = false
        procedural = false
      when "speech", "talk"
        p << e.map_child_node do |c|
          HansardSpeech.new(content: c, title: title, subtitle: subtitle, bills: bills, time: time(e), day: self,
                            logger: @logger)
        end
        question = false
        procedural = false
      when "division"
        # puts "SKIP: #{e.name} > #{full_title}"
        p << HansardDivision.new(e, title, subtitle, bills, self)
        question = false
        procedural = false
      when "petition"
        # puts "SKIP: #{e.name} > #{full_title}"
        p << HansardUnsupported.new(title, subtitle, self)
        question = false
        procedural = false
      when "question", "answer"
        # We'll skip answer because they always come in pairs of 'question' and 'answer'
        unless question
          questions = []
          f = e
          while f && (f.name == "question" || f.name == "answer")
            questions += f.map_child_node do |c|
              HansardSpeech.new(content: c, title: title, subtitle: subtitle, bills: bills, time: time(e), day: self,
                                logger: @logger)
            end
            f = f.next_sibling
          end
          p << questions
        end
        question = true
        procedural = false
      when "motionnospeech", "para", "motion", "interjection", "quote", "list", "interrupt", "amendments", "table", "separator", "continue"
        procedural_tags = %w[motionnospeech para motion interjection quote list interrupt amendments table separator
                             continue]
        unless procedural
          procedurals = []
          f = e
          while f && procedural_tags.include?(f.name)
            procedurals << HansardSpeech.new(content: f, title: title, subtitle: subtitle, bills: bills,
                                             time: time(f), day: self, logger: @logger)
            f = f.next_sibling
          end
          p << procedurals
        end
        question = false
        procedural = true
      when "subdebate.1", "subdebate.2", "subdebate.3", "subdebate.4"
        p += pages_from_debate(e)
        question = false
        procedural = false
      else
        raise "Unexpected tag #{e.name}"
      end
    end
    p
  end

  def pages
    hansard = @page.at("hansard")

    p = []
    # Step through the top-level debates
    # When something that was a page in old parlinfo web system is not supported we just return nil for it. This ensures that it is
    # still accounted for in the counting of the ids but we don't try to use it to generate any content
    p << nil
    hansard.each_child_node do |e|
      case e.name
      when "session.header"
        # Do nothing
      when "chamber.xscript", "maincomm.xscript", "fedchamb.xscript"
        e.each_child_node do |f|
          case f.name
          when "business.start", "adjournment", "interrupt", "interjection"
            p << nil
          when "debate", "petition.group"
            p += pages_from_debate(f)
          else
            raise "Unexpected tag #{f.name}"
          end
        end
      when "answers.to.questions"
        e.each_child_node do |f|
          case f.name
          when "debate"
            # Do nothing
          else
            raise "Unexpected tag #{f.name}"
          end
        end
      else
        raise "Unexpected tag #{e.name}"
      end
    end
    p
  end

  private

  def bill_url(id)
    "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:legislation/billhome/#{id}"
  end
end

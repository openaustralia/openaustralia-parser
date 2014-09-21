# -*- coding: utf-8 -*-
# vim: set ts=2 sw=2 et sts=2 ai:

require 'hpricot_additions'
require 'house'
require 'hansard_division'
require 'hansard_speech'

# Use this for sections of the Hansard that we're not currently supporting. Allows us to track
# title and subtitle.
class HansardUnsupported
  attr_reader :title, :subtitle

  def initialize(title, subtitle, day)
    @title, @subtitle, @day = title, subtitle, day
  end

  def permanent_url
    @day.permanent_url
  end
end

class HansardDay
  # On 2011-02-22 there was a tied vote and the speaker didn't need to cast a deciding
  # vote because an absolute majority was required
  ALLOW_TIED_VOTE_DATES = [Date.new(2011,2,22)]

  def initialize(page, logger = nil)
    @page, @logger = page, logger
    @house = nil
    @role_map = {}
  end

  def house
    # Cache value
    unless @house
      @house = case @page.at('chamber').inner_text.downcase
        when "senate" then House.senate
        when "reps", "house of reps" then House.representatives
        else throw "Unexpected value for contents '#{@page.at('chamber').inner_text}' of <chamber> tag"
      end
    end
    @house
  end

  def date
    # Cache value
    @date = Date.parse(@page.at('date').inner_html) unless @date
    @date
  end

  def permanent_url
    "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;adv=yes;orderBy=_fragment_number,doc_date-rev;page=0;query=Dataset%3Ahansard#{house.representatives? ? "r" : "s"},hansard#{house.representatives? ? "r" : "s"}80%20Date%3A#{date.day}%2F#{date.month}%2F#{date.year};rec=0;resCount=Default"
  end

  def in_proof?
    proof = @page.at('proof').inner_html
    @logger.error "#{date} #{house}: Unexpected value '#{proof}' inside tag <proof>" unless proof == "1" || proof == "0"
    proof == "1"
  end

  def add_speaker_to_tied_votes?
    house == House.representatives && !ALLOW_TIED_VOTE_DATES.include?(date)
  end

  # Strip any HTML/XML tags from the given text and remove new-line characters
  def strip_tags(text)
    text.gsub(/<\/?[^>]*>/, "").gsub("\r", '').gsub("\n", '')
  end

  # Search for the title tag and return its value, stripping out any HTML tags
  def title_tag_value(debate)
    # Doing this rather than calling inner_text to preserve html entities which for some reason get all screwed up by inner_text
    strip_tags(debate.search('> * > title').map{|e| e.inner_html.strip()}.join('; ')).strip()
  end

  def title(debate)
    case debate.name
    when 'debate', 'petition.group'
      title = title_tag_value(debate).strip()
      cognates = debate.search('> debateinfo > cognate > cognateinfo > title').map{|a| strip_tags(a.inner_html)}
      ([title] + cognates).join('; ')
    when 'subdebate.1', 'subdebate.2', 'subdebate.3', 'subdebate.4'
      title(debate.parent).strip()
    else
      throw "Unexpected tag #{debate.name}"
    end
  end


  def bill_id(debate)
    case debate.name
      when 'debate', 'petition.group'
        # cognate debates can have multiple bill ids
        bill_ids = debate.get_elements_by_tag_name('id.no').map { |e| strip_tags(e.inner_html.strip()) }
        if bill_ids.length > 0
          type = strip_tags(debate.search('> debateinfo > type').map { |e| e.inner_html.strip() }.join('; '))
          case type
            when '' # typically a question in writing if no type provided
              ''
            when 'Bills'
              return bill_ids.join('; ')
            else
              throw "Unexpected type #{type}"
          end
        end
      when 'subdebate.1', 'subdebate.2', 'subdebate.3', 'subdebate.4'
        bill_id(debate.parent)
      else
        throw "Unexpected tag #{debate.name}"
    end
  end

  def subtitle(debate)
    case debate.name
    when 'debate', 'petition.group'
      ""
    when 'subdebate.1'
      title_tag_value(debate).strip()
    when 'subdebate.2', 'subdebate.3', 'subdebate.4'
      front = ""
      if debate.parent.name == "subdebate.1"
        front = subtitle(debate.parent).strip()
      else
        possible_firstdebates = debate.parent.search("(subdebate.1)")
        if possible_firstdebates.length != 1
          front = title(debate).strip()
        else
          front = subtitle(possible_firstdebates[0]).strip()
        end
      end
      throw "Front title is to short! '#{front}' #{front.length}" if front.length == 0
      (front + '; ' + title_tag_value(debate)).strip()
    else
      throw "Unexpected tag #{debate.name}"
    end
  end

  def time(debate)
    # HACK: Hmmm.. check this out more
    tag = debate.at('//(time.stamp)')
    tag.inner_html if tag
  end

  def pages_from_debate(debate)

    p = []
    title = title(debate)
    subtitle = subtitle(debate)
    bill_id = bill_id(debate)

    question = false
    procedural = false

    debate.each_child_node do |e|
      case e.name
      when 'debateinfo', 'subdebateinfo', 'petition.groupinfo'
        question = false
        procedural = false
      when 'speech', 'talk'
        p << e.map_child_node {|c| HansardSpeech.new(c, title, subtitle, bill_id, time(e), self, @logger)}
        question = false
        procedural = false
      when 'division'
        #puts "SKIP: #{e.name} > #{full_title}"
        p << HansardDivision.new(e, title, subtitle, bill_id, self)
        question = false
        procedural = false
      when 'petition'
        #puts "SKIP: #{e.name} > #{full_title}"
        p << HansardUnsupported.new(title, subtitle, self)
        question = false
        procedural = false
      when 'question', 'answer'
        # We'll skip answer because they always come in pairs of 'question' and 'answer'
        unless question
          questions = []
          f = e
          while f && (f.name == 'question' || f.name == 'answer') do
            questions = questions + f.map_child_node {|c| HansardSpeech.new(c, title, subtitle, bill_id, time(e), self, @logger)}
            f = f.next_sibling
          end
          p << questions
        end
        question = true
        procedural = false
      when 'motionnospeech', 'para', 'motion', 'interjection', 'quote', 'list', 'interrupt', 'amendments', 'table', 'separator', 'continue'
        procedural_tags = %w{motionnospeech para motion interjection quote list interrupt amendments table separator continue}
        unless procedural
          procedurals = []
          f = e
          while f && procedural_tags.include?(f.name) do
            procedurals << HansardSpeech.new(f, title, subtitle, bill_id, time(f), self, @logger)
            f = f.next_sibling
          end
          p << procedurals
        end
        question = false
        procedural = true
      when 'subdebate.1', 'subdebate.2', 'subdebate.3', 'subdebate.4'
        p = p + pages_from_debate(e)
        question = false
        procedural = false
      else
        throw "Unexpected tag #{e.name}"
      end
    end
    p
  end

  def pages
    hansard = @page.at('hansard')

    p = []
    # Step through the top-level debates
    # When something that was a page in old parlinfo web system is not supported we just return nil for it. This ensures that it is
    # still accounted for in the counting of the ids but we don't try to use it to generate any content
    p << nil
    hansard.each_child_node do |e|
      case e.name
      when 'session.header'
      when 'chamber.xscript', 'maincomm.xscript', 'fedchamb.xscript'
        e.each_child_node do |e|
          case e.name
            when 'business.start', 'adjournment', 'interrupt', 'interjection'
              p << nil
            when 'debate', 'petition.group'
              p = p + pages_from_debate(e)
            else
              throw "Unexpected tag #{e.name}"
          end
        end
      when 'answers.to.questions'
        e.each_child_node do |e|
          case e.name
          when 'debate'
          else
            throw "Unexpected tag #{e.name}"
          end
        end
      else
        throw "Unexpected tag #{e.name}"
      end
    end
    p
  end
end

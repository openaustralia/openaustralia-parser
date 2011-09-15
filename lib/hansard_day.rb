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
  def initialize(page, logger = nil)
    @page, @logger = page, logger
    @house = nil
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
    house_letter = house.representatives? ? "r" : "s"
    "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:chamber/hansard#{house_letter}/#{date}/0000"
  end

  def in_proof?
    proof = @page.at('proof').inner_html
    @logger.error "#{date} #{house}: Unexpected value '#{proof}' inside tag <proof>" unless proof == "1" || proof == "0"
    proof == "1"
  end

  # Strip any HTML/XML tags from the given text and remove new-line characters
  def strip_tags(text)
    text.gsub(/<\/?[^>]*>/, "").gsub("\r", '').gsub("\n", '')
  end

  # Search for the title tag and return its value, stripping out any HTML tags
  def title_tag_value(debate)
    # Doing this rather than calling inner_text to preserve html entities which for some reason get all screwed up by inner_text
    strip_tags(debate.search('> * > title').map{|e| e.inner_html}.join('; '))
  end

  def title(debate)
    case debate.name
    when 'debate', 'petition.group'
      title = title_tag_value(debate)
      cognates = debate.search('> debateinfo > cognate > cognateinfo > title').map{|a| strip_tags(a.inner_html)}
      ([title] + cognates).join('; ')
    when 'subdebate.1', 'subdebate.2', 'subdebate.3', 'subdebate.4'
      title(debate.parent)
    else
      throw "Unexpected tag #{debate.name}"
    end
  end

  def subtitle(debate)
    case debate.name
    when 'debate', 'petition.group'
      ""
    when 'subdebate.1'
      title_tag_value(debate)
    when 'subdebate.2', 'subdebate.3', 'subdebate.4'
      subtitle(debate.parent) + '; ' + title_tag_value(debate)
    else
      throw "Unexpected tag #{debate.name}"
    end
  end

  def time(debate)
    # HACK: Hmmm.. check this out more
    tag = debate.at('//span[@class="HPS-Time"]')
    tag.inner_html if tag
  end

  def santize(text, name)
    # Remove any DOS linebreaks
    text = text.gsub("\r", '')
    # Remove any excess white space
    text = text.strip

    # Remove any trailing colons if it's a name
    if name
      if text.match(/:$/)
        text = text[0..text.length-2]
      end
    end
    
    # Clean up multiple white space in a row.
    text = text.gsub(/  +/, ' ')

    return text
  end

  def rewrite_subdebate(subdebate)
    speech_node = nil
    text_node = nil

    # To make things a little simpler we have to rework top level <a href> tags
    subdebate.search('//body/a').each do |p|
      subdebate.at('body').insert_after(Hpricot.make("<p>#{p}</p>"), p)
    end
    subdebate.search('//body/a').remove

    subdebate.each_child_node do |f|
      case f.name
      # Things to pass through un-molested
      when 'debateinfo', 'subdebateinfo'

      # Things we have to process recursively
      when 'subdebate.1', 'subdebate.2', 'subdebate.3', 'subdebate.4'
        rewrite_subdebate(f)

      # The actual transcript of the proceedings we are going to process
      when 'subdebate.text'

        f.search('/body/p').each do |p|
          # Is this a new speaker? We can tell by their existing an '<a href'
          # record with a class that starts with "Member". (There are also 
          # '<a href' records which point to bills rather then people.)
          ahref = p.search('//a')[0] if p.search('//a').length > 0
          if not ahref.nil? and ahref.attributes['type'].match(/^Member/)

            # Is this start of a speech? We can tell by the fact it has spans
            # with the HPS-Time class.
            if speech_node.nil? or p.search('[@class=HPS-Time]').length > 0:

              # Rip out the electorate
              #<span class="HPS-Electorate">Grayndler</span>
              electorate = p.search("//span[@class=HPS-Electorate]")
              electorate.remove

              # Rip out the role
              #<span class="HPS-MinisterialTitles">Leader of the House and Minister for Infrastructure and Transport</span>
              role = p.search("//span[@class=HPS-MinisterialTitles]")
              role.remove

              # Rip out the start time
              # <span class="HPS-Time">09:27</span>
              time = p.search("//span[@class=HPS-Time]")
              time.remove

              # Rip out the name
              name = santize(ahref.inner_text, true)
              p.search('//a').remove

              # Extract the text
              text = santize(p.inner_text, false)
              # Remove the leftover (—) ():
              text = text.gsub(/\(.\) \(\): /, '')

              warn "Found new speech by #{name}"

              new_node = <<EOF
<speech>
  <talker>
    <time.stamp>#{time}</time.stamp>
    <name role="metadata">#{name}</name>
    <name.id>#{ahref.attributes['href']}</name.id>
    <electorate>#{electorate}</electorate>
  </talker>
  <para>#{text}</para>
</speech>
EOF
              subdebate.append new_node
              speech_node = subdebate.search("speech")[-1]
              text_node = speech_node

            # Someone is either interjecting or continuing to speak
            else
              raise "Assertion failed! speech_node was null while trying to append a speaker" if speech_node.nil?

              # Should only be one span in this case, warn otherwise
              span = p.search("> span")
              warn "Found multiple children spans! #{span.length}" if span.length > 1

              # Class will be either "MemberContinuation" or
              # "MemberInterjecting" - strip off the "Member" part.
              case ahref.attributes['type']
              when 'MemberContinuation':
                type = "continue"
              when 'MemberInterjecting':
                type = "interjection"
              when 'MemberQuestion':
                type = "question"
              when 'MemberAnswer':
                type = "answer"
              else
                raise "Assertion failed! Unknown type #{ahref.attributes['type']}"
              end

              # Clean up the name item a little
              name = santize(ahref.inner_text, true)
              id = ahref.attributes['href']
              p.search('//a').remove

              # Clean up the text a little
              text = santize(p.inner_text, false)

              warn "Found new #{type} by #{name}"

              new_node = <<EOF
  <#{type}>
    <talker>
      <name role="metadata">#{name}</name>
      <name.id>#{id}</name.id>
    </talker>
    <para>#{text}</para>
  </#{type}>
EOF
              speech_node.append(new_node)
              text_node = speech_node.search(type)[-1]
            end

          elsif not ahref.nil? and ahref.attributes['type'].match(/^Bill/)
            # Bills don't have speeches, just dump the paragraphs into the subdebate.
            speech_node = subdebate
            text_node = subdebate

          else
            # Horrible, horrible hack. We assume anything which begins with
            # "Bill " is about discussing a bill. Couldn't figure a nicer way
            # to do this.
            #if p.inner_text.match(/^Bill /)
            #end

            case p.attributes['class']
            when 'HPS-Debate', 'HPS-SubDebate', 'HPS-SubSubDebate'
              # FIXME: We should handle bill readings a bit better then this.

              warn "Found title #{p.attributes['class']}, resetting"

##              # When it's a bill reading, we don't have speech tags. Just append
##              # directly to the subdebate.
##              if p.inner_text.strip.match(/Reading$/)
##                warn "Found new bill reading {#{p.inner_text.strip}"
##                speech_node = subdebate
##                text_node = subdebate
##
##              # When it's a message for the senate, we don't have speech tags.
##              # Just append directly to the subdebate.
##              elsif p.inner_text.strip.match(/^Consideration of Senate Message$/)
##                warn "Found new message from senate"
##                speech_node = subdebate
##                text_node = subdebate
##              elsif p.inner_text.strip.match(/^Returned from Senate$/)
##                warn "Returned from Senate"
##                speech_node = subdebate
##                text_node = subdebate
##
##              # WTF is a "consideration in detail"?
##              elsif p.inner_text.strip.match(/^Consideration in Detail$/)
##                warn "Consideration in Detail"
##                speech_node = subdebate
##                text_node = subdebate
##
##              # Otherwise, these nodes reset us back into starting state
##              else
##              end
              speech_node = nil
              text_node = nil
            when 'HPS-Normal'
              if text_node.nil? 
                warn "Ignoring para node as text_node was null\n#{p}"
              else
                warn "Found new paragraph"
                text_node.append <<EOF
  <para>#{p.inner_text}</para>
EOF
              end

            when 'HPS-Bullet'
              if text_node.nil? 
                warn "Ignoring bullet node as text_node was null\n#{p}"
              else
                warn "Found new bullet point"
                text_node.append <<EOF
  <para>* #{p.inner_text}</para>
EOF
              end

            when 'HPS-Small', 'HPS-NormalWeb'
              if text_node.nil? 
                warn "Ignoring quote node as text_node was null\n#{p}"
              else
                warn "Found new quote"
                text_node.append <<EOF
  <quote>#{p.inner_text}</quote>
EOF
              end
            else
              warn "Unknown attribute class #{p.attributes['class']}, ignoring"
            end
          end
        end
        f.search('*').remove

      when 'division'
        
      else
        f.search('*').remove
      end
    end
  end

  def pages_from_debate(debate)

    # Clean out some useless stuff
    debate.search("//debate.text").remove
    debate.search("//table[@class='HPS-TableGrid']").remove

    debate.each_child_node do |e|
      case e.name
      when 'debateinfo'

      when 'subdebate.1', 'subdebate.2', 'subdebate.3', 'subdebate.4'
        rewrite_subdebate(e)
      end
    end

    p = []
    title = title(debate)
    subtitle = subtitle(debate)

    question = false
    procedural = false

    debate.each_child_node do |e|
      case e.name
      when 'debateinfo', 'subdebateinfo', 'petition.groupinfo'
        question = false
        procedural = false
      when 'speech', 'talk'
        p << e.map_child_node {|c| HansardSpeech.new(c, title, subtitle, time(e), self, @logger)}
        question = false
        procedural = false
      when 'division'
        #puts "SKIP: #{e.name} > #{full_title}"
        p << HansardDivision.new(e, title, subtitle, self)
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
            questions = questions + f.map_child_node {|c| HansardSpeech.new(c, title, subtitle, time(e), self, @logger)}
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
            procedurals << HansardSpeech.new(f, title, subtitle, time(f), self, @logger)
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
      when 'talk.text', 'debate.text', 'subdebate.text'

      else
        throw "Unexpected tag #{e.name}"
      end
    end
    p
  end

  def pages
    p = []
    # Step through the top-level debates
    # When something that was a page in old parlinfo web system is not supported we just return nil for it. This ensures that it is
    # still accounted for in the counting of the ids but we don't try to use it to generate any content
    p << nil
    @page.at('hansard').each_child_node do |e|
      case e.name
      when 'session.header'
      when 'chamber.xscript', 'maincomm.xscript'
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

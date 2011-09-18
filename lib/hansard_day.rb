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

  # Clean up random crap in the code
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
    text = text.gsub(/\s\s+/m, ' ')

    return text
  end

  def restore_tags(text)
    text = text.gsub(/\{italic\}\s*\{\/italic\}/, "")
    text = text.gsub(/\{italic\}/, "<inline font-style='italic'>")
    text = text.gsub(/\{\/italic\}/, "</inline>")
    return text
  end


  def lookup_aph_id(aph_id, name)
    if name.match(/^The (([^S]*SPEAKER)|([^R]*RESIDENT))/i)
      if aph_id != '10000'
        warn "    Found aph id #{aph_id} of #{name}"
        @role_map[name] = aph_id
      else
        if @role_map.include? name
          aph_id = @role_map[name]
          warn "    WARNING: Looked up aph id via role_map #{name} which was #{aph_id}"
        else
          warn "    WARNING: Trying to lookup aph id via role_map #{name} but it wasn't found"
        end
      end
    end
    return aph_id
  end

  # This function is the core of the new parser.  It takes the raw
  # (sub)debate.text nodes and turns it into <speech> and more structured tags.
  # There are a lot of hard coded heuristic that depend on the unstructured
  # HTML stay a certain way - I've tried to put asserts where things might go
  # wrong rather then produce crappy output.
  def process_textnode(input_text_node)

    # Do some pre-work on the body tag to make it easier to work with.
    #--------------------------------------------------------------------------
    # To make things a little simpler we have to rework top level <a href> tags
    input_text_node.search('//body/a').each do |p|
      input_text_node.at('body').insert_after(Hpricot.make("<p>#{p}</p>"), p)
    end
    input_text_node.search('//body/a').remove

    # Many speaker interjections/continuates are not properly marked with 
    # <a href> links, we rework them so we don't have the special case below.

    #      <p class="HPS-Normal" style="direction:ltr;unicode-bidi:normal;">
    #        <span class="HPS-Normal">
    #          <span class="HPS-MemberContinuation">The DEPUTY SPEAKER:</span>  Blah blah. </span>
    #      </p>
    #  to
    #      <p class="HPS-Normal" style="direction:ltr;unicode-bidi:normal;">
    #        <span class="HPS-Normal">
    #          <a href="10000" type="MemberInterjecting">
    #            <span class="HPS-MemberInterjecting">The DEPUTY SPEAKER:</span>
    #          </a>  bla bla</span>
    #      </p>
    input_text_node.search('//body/p').each do |p|
      text = p.inner_text.strip
      if text.match(/^The (([^S]*SPEAKER)|([^R]*RESIDENT)):  /):
        puts "Doing rewrite", text
        puts "Before: #{p}"
        p.inner_html = p.inner_html.gsub(
          /<span class="HPS-Normal">.*<span class="HPS-([^"]*)">(The (([^S]*SPEAKER)|([^R]*RESIDENT))):<\/span>  (.*)<\/span>/m,
          <<EOF
      <p class="HPS-Normal" style="direction:ltr;unicode-bidi:normal;">
        <span class="HPS-Normal">
          <a href="10000" type="\\1">
            <span class="HPS-\\1">\\2:</span>
          </a>  \\6</span>
      </p>
EOF
)
        puts "After: #{p}"
      end
    end
    #--------------------------------------------------------------------------

    speech_node = nil
    text_node = nil
    amendment_node = nil

    role_map = {}

    new_xml = Hpricot('')
    input_text_node.search('/body/p').each do |p|
      # Skip empty nodes
      if p.inner_text.strip.length == 0
        warn "    Ignoring para node as it was empty\n#{p}"
        next
      end

      # We are going to remove all tags later, so any tag we want to keep
      # such as the italics, we need to do a conversion here.

      # Sometimes HPS-MemberIInterjecting are signified by just an italic
      # style applied. We are just going to assume if it has some italics
      # it's all a MemberIInterjecting
      para_text = p.inner_text.strip()
      italic_text = ""
      p.search('//span').each do |t|
        if not t.attributes['style'].nil? and t.attributes['style'].match(/italic/)
          italic_text = "#{italic_text}#{t.inner_text}"
          t.inner_html = "{italic}#{t.inner_html}{/italic}"
        end
      end
      member_iinterjecting = italic_text.strip() == para_text

      # Is this a new speaker? We can tell by there existing an '<a href'
      # record with a class that starts with "Member". 
      # (There are also '<a href' records which point to bills rather then
      # people.)
      ahref = p.search('//a')[0] if p.search('//a').length > 0
      if not ahref.nil? and ahref.attributes['type'].nil?
        warn "    Found a link without type!? #{ahref}"
        next
      end
      if not ahref.nil? and ahref.attributes['type'].match(/^Member/)

        # Is this start of a speech? We can tell by the fact it has spans
        # with the HPS-Time class.
        if speech_node.nil? or p.search('[@class=HPS-Time]').length > 0:
          # Rip out the electorate
          #<span class="HPS-Electorate">Grayndler</span>
          electorate = p.search("//span[@class=HPS-Electorate]")
          electorate.remove

          # Rip out the title
          #<span class="HPS-MinisterialTitles">Leader of the House and Minister for Infrastructure and Transport</span>
          title = p.search("//span[@class=HPS-MinisterialTitles]")
          title.remove

          # Rip out the start time
          # <span class="HPS-Time">09:27</span>
          time = p.search("//span[@class=HPS-Time]")
          time.remove

          # Pull out the name
          name = santize(ahref.inner_text, true)

          # Pull out the aph_id
          aph_id = lookup_aph_id(ahref.attributes['href'], name)

          # Rip the a link out.
          p.search('//a').remove

          # Extract the text
          text = santize(p.inner_text, false)
          # Remove the leftover (—) from electorate stuff
          text = text.gsub(/^\([^)]*\) /, '')
          # Left over from removing the HPS-Time
          text = text.gsub(/^\([^)]*\): /, '')

          warn "    Found new speech by #{name}"

          new_node = <<EOF
<speech>
  <talker>
    <time.stamp>#{time.inner_text}</time.stamp>
    <name role="metadata">#{name}</name>
    <name.id>#{aph_id}</name.id>
    <electorate>#{electorate.inner_text}</electorate>
  </talker>
  <para>#{restore_tags(text)}</para>
</speech>
EOF
          new_xml.append new_node
          speech_node = new_xml.search("speech")[-1]
          text_node = speech_node
          amendment_node = nil

        # Someone is either interjecting or continuing to speak
        else
          raise "Assertion failed! speech_node was null while trying to append a speaker" if speech_node.nil?

          # Should only be one span in this case, warn otherwise
          span = p.search("> span")
          warn "    Found multiple children spans! #{span.length}" if span.length > 1

          # Class will be either "MemberContinuation" or
          # "MemberInterjecting" - strip off the "Member" part.
          case ahref.attributes['type']
          when 'MemberContinuation'
            type = "continue"
          when 'MemberInterjecting'
            type = "interjection"
          when 'MemberQuestion'
            type = "question"
          when 'MemberAnswer'
            type = "answer"
          when 'MemberSpeech'
            type = "continue"
          else
            raise "Assertion failed! Unknown type #{ahref.attributes['type']}"
          end

          # Sometimes we get a second span with the same HPS-Type which just
          # contains someone name. Remove it.
          extra_spans = p.search("span > span[@class=HPS-#{ahref.attributes['type']}]")
          if extra_spans.length > 0
            warn "    Removing excess spans #{extra_spans.length}, removing the following text '#{extra_spans.inner_text}'"
            extra_spans.remove

          end

          # Clean up the name item a little
          name = santize(ahref.inner_text, true)

          # Pull out the aph_id
          aph_id = lookup_aph_id(ahref.attributes['href'], name)

          # Rip out the a tag
          p.search('//a').remove

          # Clean up the text a little
          text = santize(p.inner_text, false)
          if extra_spans.length > 0
            # Left over from removing the extra spans
            text = text.gsub(/^\(\s*\): /, '')
          end

          warn "    Found new #{type} by #{name}"

          new_node = <<EOF
<#{type}>
  <talker>
    <name role="metadata">#{name}</name>
    <name.id>#{aph_id}</name.id>
  </talker>
  <para>#{restore_tags(text)}</para>
</#{type}>
EOF
          speech_node.append(new_node)
          text_node = speech_node.search(type)[-1]
        end

      elsif not ahref.nil? and ahref.attributes['type'].match(/^Bill/)
        # Bills don't have speeches, just dump the paragraphs into the subdebate.
        speech_node = new_xml
        text_node = new_xml

      else
        # Some type of text paragaph
        text = santize(p.inner_text.strip(), false).strip()

        if text.length == 0
          next
        end

        case p.attributes['class']
        when 'HPS-Debate', 'HPS-SubDebate', 'HPS-SubSubDebate'
          # FIXME: We should handle bill readings a bit better then this.

          warn "    Found title #{p.attributes['class']}, resetting"
          speech_node = nil
          text_node = new_xml
          amendment_node = nil

        when 'HPS-Normal'

          if not amendment_node.nil?
            warn "      Found paragraph in an amendment"

            amendment_node.append <<EOF
<para>#{restore_tags(text)}</para>
EOF

          # We special case bill's returned from the senate with amendments
          elsif p.inner_text.match(/Bill returned from the Senate with .*amendments?/i)
            warn "    Found a bill with amendments"

            if text_node.nil?
              if speech_node.nil?
                search_node = new_xml
              else
                search_node = speech_node
              end
            else
              search_node = text_node
            end

            search_node.append <<EOF
<amendments>
  <para>#{restore_tags(text)}</para>
</amendments>
EOF
            amendment_node = search_node.search("amendments")[-1]

            speech_node = nil
            text_node = nil

          elsif text_node.nil?
            warn "    Ignoring para node as text_node was null\n#{p}"

          elsif p.search('span[@class=HPS-MemberIInterjecting]').length > 0 or
                p.search('span[@class=HPS-MemberInterjecting]').length > 0 or
                member_iinterjecting
            warn "    Found new /italics/ paragraph"
            text_node.append <<EOF
<para class="italic">#{restore_tags(text)}</para>
EOF

          else
            warn "    Found new paragraph"
            text_node.append <<EOF
<para>#{restore_tags(text)}</para>
EOF
          end

        when 'HPS-Bullet', 'HPS-SmallBullet'

          if text_node.nil? 
            warn "    Ignoring bullet node as text_node was null\n#{p}"
          else
            warn "    Found new bullet point"
            text_node.append <<EOF
<list>#{restore_tags(text)}</list>
EOF
          end

        when 'HPS-Small', 'HPS-NormalWeb'
          if not amendment_node.nil?
            warn "      Found amendment"
            amendment_node.append <<EOF
<amendment>#{restore_tags(text)}</amendment>
EOF
          elsif text_node.nil? 
            warn "    Ignoring quote node as text_node was null\n#{p}"
          else
            warn "    Found new quote"
            text_node.append <<EOF
<quote><para class="block">#{restore_tags(text)}</para></quote>
EOF
          end

        # Things we are delibaretly ignoring
        when 'HPS-DivisionSummary'

        else
          warn "    Unknown attribute class #{p.attributes['class']}, ignoring"
        end
      end
    end
    input_text_node.search('*').remove
    return new_xml
  end

  def rewrite_debate(debate, level)
    # Does this debate have subdebates? If so all the text can be found in their (sub)debate.text files
    subdebate_found = false
    debate.child_nodes.each do |f|
      case f.name
      when 'subdebate.1', 'subdebate.2', 'subdebate.3', 'subdebate.4'
        f.name = "subdebate.#{level+1}"
        f.child_nodes.each do |e| 
          case e.name
          when 'debate.text', 'subdebate.text'
            if e.inner_text.strip.length > 0
              subdebate_found = true
            end
          end
        end
      end
    end

    # We use a seperate list as we don't want the new children to appear when
    # doing the loop.
    debate_new_children = Hpricot('')

    debate.child_nodes.each do |f|
      case f.name
      # Things to pass through un-molested
      when 'debateinfo'
        warn "\nDebate #{f.at('title').inner_text}"
        debate_new_children.append "#{f}"

      when 'subdebateinfo'
        warn "  Subdebate.#{level} \"#{f.at('title').inner_text}\" @ #{f.at('(page.no)').inner_text}"
        debate_new_children.append "#{f}"

      # Things we have to process recursively
      when 'subdebate.1', 'subdebate.2', 'subdebate.3', 'subdebate.4'
        debate_new_children.append "#{ rewrite_debate(f, level+1) }"

      # The actual transcript of the proceedings we are going to process
      when 'debate.text', 'subdebate.text'
        if not subdebate_found
          debate_new_children.append "#{ process_textnode(f) }"
        end

      # Divisions are actually still the same format, so we just append them.
      when 'division'
        debate_new_children.append "#{ f }"

      # Things we are delibaretly removing
      when 'question', 'answer', 'speech', 'continue', 'interjection', 'talk'
        # pass

      else
        warn "    Removing tag #{f.name} at #{debate.name} level\n#{f}"
      end
    end

    debate.inner_html = "#{debate_new_children}"
    return debate
  end

  def preprocess_hansard(hansard)
    # Clean out some useless stuff
    hansard.search("//table[@class='HPS-TableGrid']").remove

    # Rewrite the new format back into a sane format
    hansard.search("//debate").each do |d|
      rewrite_debate(d, 0)
    end
  end


  def pages_from_debate(debate)

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
      else
        throw "Unexpected tag #{e.name}"
      end
    end
    p
  end

  def pages

    hansard = @page.at('hansard')
    preprocess_hansard(hansard)
    puts hansard

    p = []
    # Step through the top-level debates
    # When something that was a page in old parlinfo web system is not supported we just return nil for it. This ensures that it is
    # still accounted for in the counting of the ids but we don't try to use it to generate any content
    p << nil
    hansard.each_child_node do |e|
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

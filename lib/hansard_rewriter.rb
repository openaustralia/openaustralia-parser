# frozen_string_literal: true

# vim: set ts=2 sw=2 et sts=2 ai:

require "additions"

class HansardRewriter
  attr_reader :logger

  def initialize(logger = nil)
    @logger = logger
    @role_map = {}
  end

  # Clean up random crap in the code
  def santize(text, name)
    # Remove any DOS linebreaks
    text = text.gsub("\r", "")
    # Remove any excess white space
    text = text.strip

    # Remove any trailing colons if it's a name
    text = text[0..text.length - 2] if name && text.match(/:$/)

    # Clean up multiple white space in a row.
    text.gsub(/\s\s+/m, " ")
  end

  def restore_tags(text)
    text = text.gsub(%r{\{italic\}\s*\{/italic\}}, "")
    text = text.gsub(/\{italic\}/, "<inline font-style='italic'>")
    text.gsub(%r{\{/italic\}}, "</inline>")
  end

  def lookup_aph_id(aph_id, name)
    if name.match(/^The (([^S]*SPEAKER)|([^R]*RESIDENT))/i)
      if aph_id != "10000"
        logger.warn "    Found aph id #{aph_id} of #{name}"
        @role_map[name] = aph_id
      elsif @role_map.include? name
        aph_id = @role_map[name]
        logger.warn "    WARNING: Looked up aph id via role_map #{name} which was #{aph_id}"
      else
        logger.warn "    WARNING: Trying to lookup aph id via role_map #{name} but it wasn't found"
      end
    end
    aph_id
  end

  # This function is the core of the new parser.  It takes the raw
  # speech nodes and modifies them to the required format.
  # There are a lot of hard coded heuristic that depend on the unstructured
  # HTML stay a certain way - I've tried to put asserts where things might go
  # wrong rather then produce crappy output.
  #
  # Takes a string as input and returns a string. We're doing this so that
  # each function can be independently migrated from using Nokogiri to
  # Nokogiri without impacting other functions. However, it has a significant
  # performance impact so it needs to only be a temporary measure
  def process_textnode(input_text_node)
    raise "Expecting string in process_textnode" unless input_text_node.is_a?(String)

    input_text_node = Nokogiri.XML(input_text_node).children.first

    if input_text_node.search("//body/a")
      # This is probably an indication that something was done wrong in the
      # XML formatting and this is a truly nasty way to work around it
      logger.warn "Removing top level a tag (and contents) because it shouldn't be there"
      input_text_node.search("//body/a").remove
    end

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
    input_text_node.search("//body/p").each do |p|
      text = p.inner_text.strip
      next unless text.match(/^The (([^S]*SPEAKER)|([^R]*RESIDENT)):  /)

      logger.info "Doing rewrite #{text}"
      logger.info "Before: #{p}"
      p.inner_html = p.inner_html.gsub(
        %r{<span class="HPS-Normal">.*<span class="HPS-([^"]*)">(The (([^S]*SPEAKER)|([^R]*RESIDENT))):</span>  (.*)</span>}m,
        <<XML
    <p class="HPS-Normal" style="direction:ltr;unicode-bidi:normal;">
      <span class="HPS-Normal">
        <a href="10000" type="\\1">
          <span class="HPS-\\1">\\2:</span>
        </a>  \\6</span>
    </p>
XML
      )
      logger.info "After: #{p}"
    end
    #--------------------------------------------------------------------------

    speech_node = nil
    text_node = nil
    amendment_node = nil

    new_xml = Nokogiri.XML("")
    input_text_node.search("/body/p").each do |p|
      # Skip empty nodes
      if p.inner_text.strip.empty?
        logger.warn "    Ignoring para node as it was empty\n#{p}"
        next
      end

      # We are going to remove all tags later, so any tag we want to keep
      # such as the italics, we need to do a conversion here.

      # Sometimes HPS-MemberIInterjecting are signified by just an italic
      # style applied. We are just going to assume if it has some italics
      # it's all a MemberIInterjecting
      para_text = p.inner_text.strip
      italic_text = ""
      p.search("//span").each do |t|
        if !t.attributes["style"].nil? && t.attributes["style"].match(/italic/)
          italic_text = "#{italic_text}#{t.inner_text}"
          t.inner_html = "{italic}#{t.inner_html}{/italic}"
        end
      end
      member_iinterjecting = italic_text.strip == para_text

      # Is this a new speaker? We can tell by there existing an '<a href'
      # record with a class that starts with "Member".
      # (There are also '<a href' records which point to bills rather then
      # people.)
      ahref = p.search("//a")[0] unless p.search("//a").empty?
      if !ahref.nil? && ahref.attributes["type"].nil?
        logger.warn "    Found a link without type!? #{ahref}"
        next
      end
      if !ahref.nil? && ahref.attributes["type"].match(/^Member|Office/)

        # Is this start of a speech? We can tell by the fact it has spans
        # with the HPS-Time class.
        if speech_node.nil? || !p.search("[@class=HPS-Time]").empty?
          # Rip out the electorate
          # <span class="HPS-Electorate">Grayndler</span>
          electorate = p.search("//span[@class=HPS-Electorate]")
          electorate.remove

          # Rip out the title
          # <span class="HPS-MinisterialTitles">Leader of the House and Minister for Infrastructure and Transport</span>
          title = p.search("//span[@class=HPS-MinisterialTitles]")
          title.remove

          # Rip out the start time
          # <span class="HPS-Time">09:27</span>
          time = p.search("//span[@class=HPS-Time]")
          if time.inner_html =~ /\d+:\d\d/
            ripped_out_time = time.first.inner_html
          else
            # We've got a badly formed date, let's try something else
            fallback = p.inner_html.match(%r{(\d+):*<span class="HPS-Time">:*(\d\d)</span>}mi)
            ripped_out_time = "#{fallback[1]}:#{fallback[2]}" if fallback
          end
          time.remove

          # Pull out the name
          name = santize(ahref.inner_text, true)

          # Pull out the aph_id
          aph_id = lookup_aph_id(ahref.attributes["href"], name)

          # Rip the a link out.
          p.search("//a").remove

          # Extract the text
          text = santize(p.inner_text, false)
          # Remove the leftover brackets from electorate stuff
          text = text.gsub(/^\([^)]*\) /, "")
          # Left over from removing the HPS-Time
          text = text.gsub(/^\([^)]*\): /, "")

          logger.warn "    Found new speech by #{name}"

          new_node = <<~XML
            <speech>
              <talker>
                <time.stamp>#{ripped_out_time}</time.stamp>
                <name role="metadata">#{name}</name>
                <name.id>#{aph_id}</name.id>
                <electorate>#{electorate.inner_text}</electorate>
              </talker>
              <para>#{restore_tags(text)}</para>
            </speech>
          XML
          new_xml.append new_node
          speech_node = new_xml.search("speech")[-1]
          text_node = speech_node
          amendment_node = nil

        # Someone is either interjecting or continuing to speak
        else
          raise "Assertion failed! speech_node was null while trying to append a speaker" if speech_node.nil?

          # Should only be one span in this case, logger.warn otherwise
          span = p.search("> span")
          logger.warn "    Found multiple children spans! #{span.length}" if span.length > 1

          # Class will be either "MemberContinuation" or
          # "MemberInterjecting" - strip off the "Member" part.
          case ahref.attributes["type"]
          when "MemberContinuation", "MemberContinuation1", "OfficeContinuation", "OfficeContinuation1", "MemberSpeech", "MemberSpeech1"
            type = "continue"
          when "MemberInterjecting", "MemberInterjecting1", "OfficeInterjecting", "OfficeInterjecting1"
            type = "interjection"
          when "MemberQuestion", "MemberQuestion1"
            type = "question"
          when "MemberAnswer", "MemberAnswer1"
            type = "answer"
          else
            raise "Assertion failed! Unknown type #{ahref.attributes['type']}"
          end

          # Sometimes we get a second span with the same HPS-Type which just
          # contains someone name. Remove it.
          extra_spans = p.search("span > span[@class=HPS-#{ahref.attributes['type']}]")
          unless extra_spans.empty?
            logger.warn "    Removing excess spans #{extra_spans.length}, removing the following text '#{extra_spans.inner_text}'"
            extra_spans.remove

          end

          # Clean up the name item a little
          name = santize(ahref.inner_text, true)

          # Pull out the aph_id
          aph_id = lookup_aph_id(ahref.attributes["href"], name)

          # Rip out the a tag
          p.search("//a").remove

          # Clean up the text a little
          text = santize(p.inner_text, false)
          unless extra_spans.empty?
            # Left over from removing the extra spans
            text = text.gsub(/^\(\s*\): /, "")
          end

          logger.warn "    Found new #{type} by #{name}"

          new_node = <<~XML
            <#{type}>
              <talker>
                <name role="metadata">#{name}</name>
                <name.id>#{aph_id}</name.id>
              </talker>
              <para>#{restore_tags(text)}</para>
            </#{type}>
          XML
          speech_node.append(new_node)
          text_node = speech_node.search(type)[-1]
        end

      elsif !ahref.nil? && ahref.attributes["type"].match(/^Bill/)
        # Bills don't have speeches, just dump the paragraphs into the subdebate.
        speech_node = new_xml
        text_node = new_xml

      else
        # Some type of text paragaph
        text = santize(p.inner_text.strip, false).strip

        next if text.empty?

        case p.attributes["class"]
        when "HPS-Debate", "HPS-SubDebate", "HPS-SubSubDebate"
          # FIXME: We should handle bill readings a bit better then this.

          logger.warn "    Found title #{p.attributes['class']}, resetting"
          speech_node = nil
          text_node = new_xml
          amendment_node = nil

        when "HPS-Normal"

          if !amendment_node.nil?
            logger.warn "      Found paragraph in an amendment"

            amendment_node.append <<~XML
              <para>#{restore_tags(text)}</para>
            XML

          # We special case bill's returned from the senate with amendments
          elsif p.inner_text.match(/Bill returned from the Senate with .*amendments?/i)
            logger.warn "    Found a bill with amendments"

            search_node = if text_node.nil?
                            if speech_node.nil?
                              new_xml
                            else
                              speech_node
                            end
                          else
                            text_node
                          end

            search_node.append <<~XML
              <amendments>
                <para>#{restore_tags(text)}</para>
              </amendments>
            XML
            amendment_node = search_node.search("amendments")[-1]

            speech_node = nil
            text_node = nil

          elsif text_node.nil?
            logger.warn "    Ignoring para node as text_node was null\n#{p}"

          elsif !p.search("span[@class=HPS-MemberIInterjecting]").empty? ||
                !p.search("span[@class=HPS-MemberInterjecting]").empty? ||
                member_iinterjecting
            logger.warn "    Found new /italics/ paragraph"
            text_node.append <<~XML
              <para class="italic">#{restore_tags(text)}</para>
            XML

          else
            logger.warn "    Found new paragraph"
            text_node.append <<~XML
              <para>#{restore_tags(text)}</para>
            XML
          end

        when "HPS-Bullet", "HPS-SmallBullet"

          if text_node.nil?
            logger.warn "    Ignoring bullet node as text_node was null\n#{p}"
          else
            logger.warn "    Found new bullet point"
            text_node.append <<~XML
              <list>#{restore_tags(text)}</list>
            XML
          end

        when "HPS-Small", "HPS-NormalWeb"
          if !amendment_node.nil?
            logger.warn "      Found amendment"
            amendment_node.append <<~XML
              <amendment>#{restore_tags(text)}</amendment>
            XML
          elsif text_node.nil?
            logger.warn "    Ignoring quote node as text_node was null\n#{p}"
          else
            logger.warn "    Found new quote"
            text_node.append <<~XML
              <quote><para class="block">#{restore_tags(text)}</para></quote>
            XML
          end

        # Things we are delibaretly ignoring
        when "HPS-DivisionSummary"

        else
          logger.warn "    Unknown attribute class #{p.attributes['class']}, ignoring"
        end
      end
    end
    input_text_node.search("*").remove
    new_xml.to_s
  end

  def rewrite_debate(debate, level)
    # Does this debate have subdebates? If so all the text can be found in their (sub)debate.text files
    subdebate_found = false
    debate.child_nodes.each do |f|
      case f.name
      when "subdebate.1", "subdebate.2", "subdebate.3", "subdebate.4"
        f.name = "subdebate.#{level + 1}"
        f.child_nodes.each do |e|
          case e.name
          when "debate.text", "subdebate.text"
            subdebate_found = true unless e.inner_text.strip.empty?
          end
        end
      end
    end

    # We use a seperate list as we don't want the new children to appear when
    # doing the loop.
    debate_new_children = Nokogiri.XML("")

    debate.child_nodes.each do |f|
      case f.name
      # Things to pass through un-molested
      when "debateinfo"
        logger.warn "\nDebate #{f.at('title').inner_text}"
        debate_new_children.append f.to_s

      when "subdebate.text"
        if f.at("a") && (f.at("a")["type"] == "Bill")
          logger.warn "\nSubdebate.text #{f.at('body').inner_text}"
          debate_new_children.append f.to_s
        end

      when "subdebateinfo"
        logger.warn "  Subdebate.#{level} \"#{f.at('title').inner_text}\" @ #{f.at('(page.no)').inner_text}"
        debate_new_children.append f.to_s

      # Things we have to process recursively
      when "subdebate.1", "subdebate.2", "subdebate.3", "subdebate.4"
        debate_new_children.append rewrite_debate(f, level + 1).to_s

      # The actual transcript of the proceedings we are going to process
      when "question", "answer", "speech"
        unless subdebate_found
          # We're interested in the talk.text node but have to find it manually due to a bug
          # with Nokogiri xpath meaning nodes with a dot '.' in the name are not found.
          talk = f.child_nodes.detect { |node| node.name == "talk.text" }
          debate_new_children.append process_textnode(talk.to_s) if talk
        end

      # Divisions are actually still the same format, so we just append them.
      when "division"
        debate_new_children.append f.to_s

      # Things we are delibaretly removing
      when "continue", "interjection", "talk", "debate.text"
        # pass

      else
        logger.warn "    Removing tag #{f.name} at #{debate.name} level\n#{f}"
      end
    end

    debate.inner_html = debate_new_children.to_s
    debate
  end

  def rewrite_xml(hansard)
    # Clean out some useless stuff
    hansard.search("//table[@class='HPS-TableGrid']").remove

    # Rewrite the new format back into a sane format
    hansard.search("//debate").each do |d|
      rewrite_debate(d, 0)
    end
    hansard
  end
end

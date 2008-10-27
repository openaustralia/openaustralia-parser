require 'rubygems'
require 'activesupport'
require 'hpricot_additions'

$KCODE = 'u'

class HansardSpeech
  attr_reader :logger
  
  def initialize(content, page, logger = nil)
    @content, @page, @logger = content, page, logger
  end
  
  # The url of a speech is just the url of the page that it comes from
  def permanent_url
    @page.permanent_url
  end
  
  # The time of a speech is just the time of the page that the speech is on
  def time
    @page.time
  end
  
  def speakername
    extract_speakername[0]
  end
  
  def aph_id
    extract_speakername[1]
  end
  
  def interjection
    extract_speakername[2]
  end

  def extract_speakername
    # If there are multiple <name> tags prefer the one with the attribute role='display'
    talkername_tag1 = @content.at('name[@role=metadata]')
    talkername_tag2 = @content.at('name[@role=display]')
    # Only use the 'metadata' if it has brackets in it
    if talkername_tag1 && talkername_tag1.inner_html =~ /\(.*\)/
      talkername_tag = talkername_tag1
    else
      talkername_tag = talkername_tag2 || @content.at('name')
    end
    name = talkername_tag ? talkername_tag.inner_html : nil
    aph_id_tag = @content.at('//(name.id)')
    aph_id = aph_id_tag ? aph_id_tag.inner_html : nil
    interjection = !@content.at('interjection').nil?
    
    if name.nil? && aph_id.nil?
      # As a last resort try searching for interjection text
      m = strip_tags(@content).match(/([a-z].*) interjecting/i)
      if m
        name = m[1]
        interjection = true
      else
        m = strip_tags(@content).match(/^([a-z].*?)—/i)
        if m and HansardSpeech.generic_speaker?(m[1])
          name = m[1]
          interjection = false
        end
      end
    end
    
    [name, aph_id, interjection]
  end  

  def HansardSpeech.strip_leading_dash(text)
    # Unicode Character 'Non-breaking hyphen' (U+2011)
    nbhyphen = [0x2011].pack('U')
    
    t = text.chars.gsub(nbhyphen, '-')
    # TODO: Not handling dashes and nbsp the same here. Should really be stripping whitespace completely before doing
    # anything for consistency sake.
    if t.strip[0..0] == '—'
      t.sub('—', '')
    # Also remove first non-breaking space (Really should remove them all but we're doing it this way for compatibility
    # with the previous parser
    elsif t[0] == 160
      t[1..-1]
    else
      t
    end
  end
  
  def HansardSpeech.clean_content_inline(e)
    text = strip_leading_dash(e.inner_html)

    # TODO: Fix the link here
    if e.attributes.keys == ['ref']
      '<a href="??">' + text + '</a>'
    elsif e.attributes.keys == ['font-size']
      text
    elsif e.attributes.keys.include?('font-style')
      if e.attributes['font-style'] == 'italic'
        '<i>' + text + '</i>'
      else
        throw "Unexpected font-style value #{e.attributes['font-style']}"
      end
    elsif e.attributes.keys == ['font-weight']
      if e.attributes['font-weight'] == 'bold'
        # Workaround for badly marked up content. If a bold item is surrounded in brackets assume it is a name and remove it
        # Alternatively if the bold item is a generic name, remove it as well
        if (e.inner_html[0..0] == '(' && e.inner_html[-1..-1] == ')') || generic_speaker?(e.inner_html)
          ''
        else
          '<b>' + text + '</b>'
        end
      else
        throw "Unexpected font-weight value #{e.attributes['font-weight']}"
      end
    elsif e.attributes.keys.empty?
      '<p>' + text + '</p>'
    else
      throw "Unexpected attributes #{e.attributes.keys.join(', ')}"
    end
  end
  
  # Pass a <para>Some text</para> block. Returns cleaned "Some text"
  def HansardSpeech.clean_content_para_content(e)
    t = ""
    e.children.each do |c|
      if !c.respond_to?(:name)
        t << strip_leading_dash(c.to_s)
      elsif c.name == 'inline'
        t << clean_content_inline(c)
      else
        throw "Unexpected tag #{c.name}"
      end
    end
    t
  end
  
  # Pass a <para>Some text</para> block. Returns cleaned "<p>Some text</p>"
  def HansardSpeech.clean_content_para(e)
    atts = e.attributes.keys
    # We're not going to pay any attention to the following attribute
    atts.delete('pgwide')
    
    type = ""
    if ['motion', 'quote', 'amendment'].include?(e.parent.name)
      type = "italic"
    end
    if atts.empty?
      # Do nothing
    elsif atts == ['class']
      case e.attributes['class']
      when 'italic'
        type = 'italic'
      when 'bold'
        type = 'bold'
      when 'block', 'ParlAmend', 'subsection'
      else
        throw "Unexpected value for class attribute of para #{e.attributes['class']}" 
      end
    else
      throw "Unexpected <para> attributes #{atts.join(', ')}"
    end

    case type
    when ""
      '<p>' + clean_content_para_content(e) + '</p>'
    when 'italic'
      '<p class="' + type + '">' + clean_content_para_content(e) + '</p>'
    when 'bold'
      '<b><p>' + clean_content_para_content(e) + '</p></b>'
    else
      throw "Unexpected type value #{type}"
    end
  end
  
  def HansardSpeech.clean_content_list(e)
    l = ""
    if e.attributes.keys == ['type']
      if ['loweralpha', 'unadorned', 'decimal', 'lowerroman'].include?(e.attributes['type'])
        e.children.each do |e|
          next unless e.respond_to?(:name)
          if e.name == 'item'
            if e.attributes.keys == ['label']
              l << '<dt>' + e.attributes['label'] + '</dt>'
              d = ""
              e.children.each do |e|
                next unless e.respond_to?(:name)
                if e.name == 'para'
                  d << clean_content_para_content(e)
                elsif e.name == 'list'
                  d << clean_content_list(e)
                elsif e.name == 'table'
                  d << clean_content_table(e)
                else
                  throw "Unexpected tag #{e.name}"
                end
              end
              l << '<dd>' + d + '</dd>'
            else
              throw "Unexpected attributes #{e.attributes.keys.join(', ')}"
            end
          else
            throw "Unexpected tag #{e.name}"
          end
        end
        '<dl>' + l + '</dl>'
      elsif ['bullet'].include?(e.attributes['type'])
        e.children.each do |e|
          next unless e.respond_to?(:name)
          if e.name == 'item'
            if e.attributes.keys.empty?
              e.children.each do |e|
                next unless e.respond_to?(:name)
                if e.name == 'para'
                  l << '<li>' + e.inner_html + '</li>'
                elsif e.name == 'list'
                  l << clean_content_list(e)
                else
                  throw "Unexpected tag #{e.name}"
                end
              end
            else
              throw "Unexpected attributes #{e.attributes.keys.join(', ')}"
            end
          else
            throw "Unexpected tag #{e.name}"
          end
        end
        '<ul>' + l + '</ul>'        
      else
        throw "Unexpected type value #{e.attributes['type']}"
      end      
    else
      throw "Unexpected attributes #{e.attributes.keys.join(', ')}"
    end
  end

  def HansardSpeech.clean_content_entry(e)
    t = ""
    e.each_child_node do |c|
      throw "Unexpected tag #{c.name}" unless c.name == 'para'
      t << clean_content_para(c)
    end
    t
  end
  
  def HansardSpeech.clean_content_row(e)
    t = ""
    e.children.each do |c|
      next unless c.respond_to?(:name)
      if c.name == 'entry'
        if c.parent.parent.name == 'thead'
          #t << '<th>' + clean_content_entry(c) + '</th>'
          t << '<td>' + clean_content_entry(c) + '</td>'
        elsif c.parent.parent.name == 'tbody'
          t << '<td>' + clean_content_entry(c) + '</td>'
        else
          throw "Unexpected tag #{c.parent.parent.name}"
        end
      else
        throw "Unexpected tag #{c.name}"
      end
    end
    '<tr>' + t + '</tr>'
  end
  
  def HansardSpeech.clean_content_thead(e)
    t = ""
    e.each_child_node do |c|
      throw "Unexpected tag #{c.name}" unless c.name == 'row'
      t << clean_content_row(c)
    end
    t
  end
  
  def HansardSpeech.clean_content_tbody(e)
    t = ""
    e.each_child_node do |c|
      throw "Unexpected tag #{c.name}" unless c.name == 'row'
      t << clean_content_row(c)
    end
    t
  end
  
  def HansardSpeech.clean_content_tgroup(e)
    t = ""
    e.each_child_node do |c|
      case c.name
      when "colspec"
      when "thead"
        t << clean_content_thead(c)
      when "tbody"
        t << clean_content_tbody(c)
      else
        throw "Unexpected tag #{c.name}"
      end
    end
    t    
  end
  
  def HansardSpeech.clean_content_table(e)
    t = ""
    e.each_child_node do |c|
      throw "Unexpected tag #{c.name}" unless c.name == 'tgroup'
      t << clean_content_tgroup(c)
    end
    # Not sure if I really should put border="0" here. Hmmm...
    '<table border="0">' + t + '</table>'
  end
  
  def HansardSpeech.clean_content_quote(e)
    t = ""
    e.each_child_node do |e|
      case e.name
      when 'para'
        t << '<p class="italic">' + clean_content_para_content(e) + '</p>'
      when 'list'
        t << clean_content_list(e)
      when 'table'
        t << clean_content_table(e)
      else
        throw "Unexpected tag #{e.name}"
      end
    end
    t
  end
  
  def HansardSpeech.clean_content_interjection(e)
    c = ""
    e.each_child_node do |e|
      throw "Unexpected tag #{e.name}" unless e.name == 'talk.start'
      c << clean_content_talk_start(e)
    end
    c
  end
  
  def HansardSpeech.clean_content_talk_start(e)
    c = ""
    e.each_child_node do |e|
      case e.name
      when 'para'
        c << clean_content_para(e)
      when 'talker'
      else
        throw "Unexpected tag #{e.name}"
      end
    end
    c
  end
  
  def HansardSpeech.clean_content_amendment(e)
    t = ""
    e.each_child_node do |c|
      throw "Unexpected tag #{c.name}" unless c.name == 'para'
      t << clean_content_para(c)
    end
    t
  end
  
  def HansardSpeech.clean_content_amendments(e)
    t = ""
    e.each_child_node do |c|
      throw "Unexpected tag #{c.name}" unless c.name == 'amendment'
      t << clean_content_amendment(c)
    end
    t
  end
  
  def HansardSpeech.clean_content_motion(e)
    c = ""
    e.each_child_node do |e|
      case e.name
      when 'para'
        c << HansardSpeech.clean_content_para(e)
      when 'list'
        c << HansardSpeech.clean_content_list(e)
      else
        throw "Unexpected tag #{e.name}"
      end
    end
    c
  end
  
  def HansardSpeech.clean_content_motionnospeech(e)
    t = ""
    e.each_child_node do |c|
      case c.name
      when 'name', 'electorate', 'role', 'time.stamp'
      when 'inline'
        t << clean_content_inline(c)
      when 'motion'
        t << clean_content_motion(c)
      when 'para'
        t << clean_content_para(c)
      else
        throw "Unexpected tag #{c.name}"
      end
    end
    t
  end
  
  def HansardSpeech.clean_content_interrupt(e)
    t = ""
    e.each_child_node do |c|
      throw "Unexpected tag #{c.name}" unless c.name == 'para'
      t << clean_content_para(c)
    end
    '<b>' + t + '</b>'
  end
  
  def HansardSpeech.clean_content_continue(e)
    t = ""
    e.each_child_node do |c|
      throw "Unexpected tag #{c.name}" unless c.name == 'talk.start'
      t << clean_content_talk_start(c)
    end
    t
  end
  
  def clean_content
    c = ""
    e = @content

    case e.name
    when 'talk.start'
      c << HansardSpeech.clean_content_talk_start(e)
    when 'motion'
      c << HansardSpeech.clean_content_motion(e)
    when 'list'
      c << HansardSpeech.clean_content_list(e)
    when 'para'
      c << HansardSpeech.clean_content_para(e)
    when 'quote'
      c << HansardSpeech.clean_content_quote(e)
    when 'interjection'
      c << HansardSpeech.clean_content_interjection(e)
    when 'amendments'
      c << HansardSpeech.clean_content_amendments(e)
    when 'continue'
      e.each_child_node do |e|
        throw "Unexpected tag #{e.name}" unless e.name == 'talk.start'
        c << HansardSpeech.clean_content_talk_start(e)
      end
    when 'motionnospeech'
      c << HansardSpeech.clean_content_motionnospeech(e)
    when 'interrupt'
      c << HansardSpeech.clean_content_interrupt(e)
    when 'table'
      c << HansardSpeech.clean_content_table(e)
    when 'tggroup', 'tgroup', 'amendment', 'talker', 'name', 'electorate', 'role', 'time.stamp', 'inline', 'separator'
    else
      throw "Unexpected tag #{e.name}"
    end

    Hpricot.XML(c)
  end

  def remove_generic_speaker_names(content)
    if generic_speaker?(speakername) and !interjection
      #remove everything before the first hyphen
      return Hpricot(content.to_s.gsub!(/^<p[^>]*>.*?—/i, "<p>"))
    end
    content
  end

  def strip_tags(doc)
    str=doc.to_s
    str.gsub(/<\/?[^>]*>/, "")
  end

  def extract_aph_id_from_speaker_url(speaker_url)
    if speaker_url =~ /^view_document.aspx\?TABLE=biogs&ID=(\d+)$/
      $~[1].to_i
    elsif speaker_url.nil? || speaker_url == "view_document.aspx?TABLE=biogs&ID="
      nil
    else
      logger.error "Speaker link has unexpected format: #{speaker_url} on #{@page.permanent_url}" if logger
      nil
    end
  end  

  def HansardSpeech.generic_speaker?(speakername)
    speakername =~ /^(an? )?(honourable|opposition|government) (member|senator)s?$/i
  end
end

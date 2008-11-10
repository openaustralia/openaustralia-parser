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

    attributes_keys = e.attributes.keys
    # Always ignore font-size
    attributes_keys.delete('font-size')

    # A special case here. Ugly HACK
    if e.attributes.keys.empty?
      text = '<p>' + text + '</p>'
    end
    
    if attributes_keys.delete('ref')
      # We're going to assume these links always point to Bills.
      link = "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:legislation/billhome/#{e.attributes['ref']}"
      text = '<a href="' + link + '">' + text + '</a>'
    end

    if attributes_keys.delete('font-style')
      if e.attributes['font-style'] == 'italic'
        text = '<i>' + text + '</i>'
      else
        throw "Unexpected font-style value #{e.attributes['font-style']}"
      end
    end
        
    if attributes_keys.delete('font-weight')
      if e.attributes['font-weight'] == 'bold'
        # Workaround for badly marked up content. If a bold item is surrounded in brackets assume it is a name and remove it
        # Alternatively if the bold item is a generic name, remove it as well
        if (e.inner_html[0..0] == '(' && e.inner_html[-1..-1] == ')') || generic_speaker?(e.inner_html)
          text = ''
        else
          text = '<b>' + text + '</b>'
        end
      else
        throw "Unexpected font-weight value #{e.attributes['font-weight']}"
      end
    end

    # TODO: This is wrong but will do for the time being
    attributes_keys.delete('font-variant')

    unless attributes_keys.empty?
      throw "Unexpected attributes #{attributes_keys.join(', ')}"
    end
    
    text
  end
  
  def HansardSpeech.clean_content_graphic(e)
    throw "Unexpected attributes for graphic tag: #{e.attributes.keys.join(', ')}" unless e.attributes.keys == ['href']
    # TODO: Probably the path needs to be different depending on whether Reps or Senate
    '<img src="http://parlinfoweb.aph.gov.au/parlinfo/Repository/Chamber/HANSARDR/' + e.attributes['href'] + '"/>'
  end
  
  # Pass a <para>Some text</para> block. Returns cleaned "Some text"
  def HansardSpeech.clean_content_para_content(e)
    t = ""
    e.children.each do |c|
      if !c.respond_to?(:name)
        t << strip_leading_dash(c.to_s)
      elsif c.name == 'inline'
        t << clean_content_inline(c)
      elsif c.name == 'graphic'
        t << clean_content_graphic(c)
      # This is silly. Why should there be a <para> inside a <para>?
      elsif c.name == 'para'
        t << clean_content_para(c)
      else
        throw "Unexpected tag #{c.name}"
      end
    end
    t
  end
  
  # Pass a <para>Some text</para> block. Returns cleaned "<p>Some text</p>"
  def HansardSpeech.clean_content_para(e, override_type = nil)
    atts = e.attributes.keys
    # We're not going to pay any attention to the following attribute
    atts.delete('pgwide')
    
    type = ""
    if override_type
      type = override_type
    # TODO: Consistently use either the mechanism above or below not this half-assed confusing nonsense here
    elsif ['motion', 'quote', 'amendment'].include?(e.parent.name)
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
      when 'block', 'ParlAmend', 'subsection', 'ItemHead', 'Item', 'indenta', 'hdg5s', 'smalltableleft', 'Definition', 'indentii', 'centre', 'smalltablejustified', 'heading'
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
    attributes_keys = e.attributes.keys
    # Always ignore the following attribute
    attributes_keys.delete('pgwide')
    
    # TODO: Check whether there are any other attributes other than 'label' being used
    
    # We figure out whether to generate a <dl> or <ul> based on whether the child tags all have a 'label' attribute or not
    label = e.at('> item').has_attribute?('label') if e.at('> item')
    # Check that all the children are consistent
    e.search('> item').each do |c|
      if c.has_attribute?('label') != label
        throw "Children of <list> are using the 'label' attribute inconsistently"
      end
    end
    
    if attributes_keys.delete('type')
      if ['bullet', 'loweralpha', 'loweralpha-dotted', 'unadorned', 'decimal', 'decimal-dotted', 'lowerroman', 'lowerroman-dotted', 'upperalpha'].include?(e.attributes['type'])
        e.each_child_node do |e|
          case e.name
          when 'item'
            if label
              l << '<dt>' + e.attributes['label'] + '</dt>'
              d = ""
              e.each_child_node do |e|
                case e.name
                when 'para'
                  d << clean_content_para_content(e)
                when 'list'
                  d << clean_content_list(e)
                when 'table'
                  d << clean_content_table(e)
                else
                  throw "Unexpected tag #{e.name}"
                end
              end
              l << '<dd>' + d + '</dd>'
            else
              e.each_child_node do |e|
                case e.name
                when 'para'
                  l << '<li>' + clean_content_para_content(e) + '</li>'
                when 'list'
                  l << clean_content_list(e)
                else
                  throw "Unexpected tag #{e.name}"
                end
              end
            end
          else
            throw "Unexpected tag #{e.name}"
          end
        end
        if label
          l = '<dl>' + l + '</dl>'
        else
          l = '<ul>' + l + '</ul>'
        end
      else
        throw "Unexpected type value #{e.attributes['type']}"
      end
    end
    
    unless attributes_keys.empty?
      throw "Unexpected attributes #{e.attributes.keys.join(', ')} with values #{e.attributes.values.join(', ')}"
    end
    l
  end

  def HansardSpeech.clean_content_entry(e, override_type = nil)
    t = ""
    e.each_child_node do |c|
      case c.name
      when 'para'
        t << clean_content_para(c, override_type)
      when 'quote'
        t << clean_content_quote(c)
      else
        throw "Unexpected tag #{c.name}"
      end
    end
    t
  end
  
  def HansardSpeech.clean_content_row(e, override_type = nil)
    t = ""
    e.each_child_node do |c|
      case c.name
      when 'entry'
        case c.parent.parent.name
        when 'thead', 'tbody'
          attributes = 'valign="top"'
          if c.attributes['colspan']
            attributes << ' colspan="' + c.attributes['colspan'] + '"'
          end
          t << '<td ' + attributes + '>' + clean_content_entry(c, override_type) + '</td>'
        else
          throw "Unexpected tag #{c.parent.parent.name}"
        end
      else
        throw "Unexpected tag #{c.name}"
      end
    end
    '<tr>' + t + '</tr>'
  end
  
  def HansardSpeech.clean_content_thead(e, override_type = nil)
    t = ""
    e.each_child_node do |c|
      throw "Unexpected tag #{c.name}" unless c.name == 'row'
      t << clean_content_row(c, override_type)
    end
    t
  end
  
  def HansardSpeech.clean_content_tbody(e, override_type = nil)
    t = ""
    e.each_child_node do |c|
      throw "Unexpected tag #{c.name}" unless c.name == 'row'
      t << clean_content_row(c, override_type)
    end
    t
  end
  
  def HansardSpeech.clean_content_tgroup(e, override_type = nil)
    t = ""
    e.each_child_node do |c|
      case c.name
      when "colspec"
      when "thead"
        t << clean_content_thead(c, override_type)
      when "tbody"
        t << clean_content_tbody(c, override_type)
      else
        throw "Unexpected tag #{c.name}"
      end
    end
    t    
  end
  
  def HansardSpeech.clean_content_table(e, override_type = nil)
    t = ""
    e.each_child_node do |c|
      throw "Unexpected tag #{c.name}" unless c.name == 'tgroup'
      t << clean_content_tgroup(c, override_type)
    end
    # Not sure if I really should put border="0" here. Hmmm...
    '<table border="0">' + t + '</table>'
  end
  
  def HansardSpeech.clean_content_quote(e)
    t = ""
    e.each_child_node do |e|
      case e.name
      when 'para'
        t << clean_content_para(e, 'italic')
      when 'list'
        t << clean_content_list(e)
      when 'table'
        t << clean_content_table(e, 'italic')
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
        c << clean_content_para(e)
      when 'list'
        c << clean_content_list(e)
      when 'table'
        c << clean_content_table(e)
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
      logger.error "Speaker link has unexpected format: #{speaker_url}" if logger
      nil
    end
  end  

  def HansardSpeech.generic_speaker?(speakername)
    speakername =~ /^(an? )?(honourable|opposition|government) (member|senator)s?$/i
  end
end

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
    # TODO: Probably the path needs to be different depending on whether Reps or Senate
    '<img src="http://parlinfoweb.aph.gov.au/parlinfo/Repository/Chamber/HANSARDR/' + e.attributes['href'] + '"/>'
  end
  
  # Pass a <para>Some text</para> block. Returns cleaned "Some text"
  def HansardSpeech.clean_content_para_content(e)
    t = ""
    e.children.each do |c|
      if c.respond_to?(:name)
        t << clean_content_any(c)
      else
        t << strip_leading_dash(c.to_s)
      end
    end
    t
  end
  
  # Pass a <para>Some text</para> block. Returns cleaned "<p>Some text</p>"
  def HansardSpeech.clean_content_para(e, override_type = nil)
    if override_type
      type = override_type
    else
      type = ""
    end
    
    case e.attributes['class']
    when 'italic'
      type = 'italic'
    when 'bold'
      type = 'bold'
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
  
  def HansardSpeech.clean_content_item(e)
    d = ""
    e.each_child_node do |f|
      case f.name
      when 'para'
        d << clean_content_para_content(f)
      when 'list'
        d << clean_content_list(f)
      when 'table'
        d << clean_content_table(f)
      else
        throw "Unexpected tag #{f.name}"
      end
    end
    if e.has_attribute?('label')
      '<dt>' + e.attributes['label'] + '</dt><dd>' + d + '</dd>'
    else
      '<li>' + d + '</li>'
    end
  end
  
  def HansardSpeech.clean_content_list(e)
    # We figure out whether to generate a <dl> or <ul> based on whether the child tags all have a 'label' attribute or not
    label = e.at('> item').has_attribute?('label') if e.at('> item')
    # Check that all the children are consistent
    e.search('> item').each do |c|
      if c.has_attribute?('label') != label
        throw "Children of <list> are using the 'label' attribute inconsistently"
      end
    end
    
    if label
      '<dl>' + clean_content_recurse(e) + '</dl>'
    else
      '<ul>' + clean_content_recurse(e) + '</ul>'
    end
  end

  def HansardSpeech.clean_content_entry(e, override_type = nil)
    attributes = 'valign="top"'
    if e.attributes['colspan']
      attributes << ' colspan="' + e.attributes['colspan'] + '"'
    end
    '<td ' + attributes + '>' + clean_content_recurse(e, override_type) + '</td>'
  end
  
  def HansardSpeech.clean_content_table(e, override_type = nil)
    # Not sure if I really should put border="0" here. Hmmm...
    '<table border="0">' + clean_content_recurse(e, override_type) + '</table>'
  end
  
  def HansardSpeech.clean_content_any(e, override_type = nil)
    case e.name
    when 'amendment', 'motion', 'quote'
      clean_content_recurse(e, 'italic')
    when 'talk.start', 'amendments', 'motionnospeech', 'interjection', 'continue'
      clean_content_recurse(e)
    when 'tgroup', 'thead', 'tbody'
      clean_content_recurse(e, override_type)
    when 'para'
      clean_content_para(e, override_type)
    when 'list'
      clean_content_list(e)
    when 'table'
      clean_content_table(e, override_type)
    when 'inline'
      clean_content_inline(e)
    when 'interrupt'
      '<b>' + clean_content_recurse(e) + '</b>'
    when 'row'
      '<tr>' + clean_content_recurse(e, override_type) + '</tr>'
    when 'entry'
      clean_content_entry(e, override_type)
    when 'item'
      clean_content_item(e)
    when 'inline'
      clean_content_inline(e)
    when 'graphic'
      clean_content_graphic(e)
    when 'talker', 'name', 'electorate', 'role', 'time.stamp', 'tggroup', 'amendment', 'inline', 'separator', 'colspec'
      ""
    else
      throw "Unexpected tag #{e.name}"
    end
  end
  
  def HansardSpeech.clean_content_recurse(e, override_type = nil)
    t = ""
    e.each_child_node do |e|
      t << clean_content_any(e, override_type)
    end
    t    
  end
  
  def clean_content
    Hpricot.XML(HansardSpeech.clean_content_any(@content))
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

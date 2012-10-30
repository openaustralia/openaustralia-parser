require 'environment'
require 'active_support'
require 'hpricot_additions'
require 'name'

$KCODE = 'u'

class HansardSpeech
  attr_reader :logger, :title, :subtitle, :time, :day, :interjection, :continuation
  
  def initialize(content, title, subtitle, time, day, logger = nil)
    @content, @title, @subtitle, @time, @day, @logger = content, title, subtitle, time, day, logger
    @interjection = name?('interjection')
    @continuation = name?('continue')
  end
  
  # The url of a speech is just the url of the day that it comes from
  def permanent_url
    day.permanent_url
  end
  
  def speakername
    # First try to lookup name using the proper tags. If that doesn't work try looking in the text
    speakername_from_tag || speakername_from_text
  end
  
  def aph_id
    aph_id_tag = @content.at('//(name.id)')
    aph_id_tag ? aph_id_tag.inner_html : nil
  end
  
  private
  
  def speakername_from_tag
    # If there are multiple <name> tags prefer the one with the attribute role='display'
    talkername_tag1 = @content.at('name[@role=metadata]')
    # Only use the 'metadata' if it has brackets in it
    if talkername_tag1 && talkername_tag1.inner_html =~ /\(.*\)/
      talkername_tag = talkername_tag1
    else
      talkername_tag = @content.at('name[@role=display]') || @content.at('name')
    end
    talkername_tag ? talkername_tag.inner_html : nil
  end
  
  def speakername_from_text
    if strip_tags(@content) =~ /^([a-z].*?)( interjecting)?—/i and HansardSpeech.generic_speaker?($~[1])
      $~[1]
    end
  end
  
  public
  
  def HansardSpeech.strip_leading_dash(text)
    # Unicode Character 'Non-breaking hyphen' (U+2011)
    nbhyphen = [0x2011].pack('U')
    nbsp = [160].pack('U')
    
    t = text.mb_chars.gsub(nbhyphen, '-')
    # TODO: Not handling dashes and nbsp the same here. Should really be stripping whitespace completely before doing
    # anything for consistency sake.
    if t.strip[0..0] == '—'
      t.sub('—', '')
    # Also remove first non-breaking space (Really should remove them all but we're doing it this way for compatibility
    # with the previous parser
    elsif t[0] == nbsp
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

    if attributes_keys.delete('ref')
      # We're going to assume these links always point to Bills.
      link = "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:legislation/billhome/#{e.attributes['ref']}"
      text = '<a href="' + link + '">' + text + '</a>'
    end

    if attributes_keys.delete('font-style')
      throw "Unexpected font-style value #{e.attributes['font-style']}" unless e.attributes['font-style'] == 'italic'
      
      text = '<i>' + text + '</i>'
    end
        
    if attributes_keys.delete('font-weight')
      throw "Unexpected font-weight value #{e.attributes['font-weight']}" unless e.attributes['font-weight'] == 'bold'

      # Workaround for badly marked up content. If a bold item is surrounded in brackets assume it is a name and remove it
      # Alternatively if the bold item is a generic name, remove it as well
      if e.inner_html =~ /^\(.*\)$/ || generic_speaker?(e.inner_html)
        text = ''
      else
        text = '<b>' + text + '</b>'
      end
    end

    if attributes_keys.delete('font-variant')
      case e.attributes['font-variant']
      when 'superscript'
        text = '<sup>' + text + '</sup>'
      when 'subscript'
        text = '<sub>' + text + '</sub>'
      else
        throw "Unexpected font-variant value #{e.attributes['font-variant']}"
      end
    end
    
    throw "Unexpected attributes #{attributes_keys.join(', ')}" unless attributes_keys.empty?
    
    # Handle inlines for motionnospeech in a special way
    if e.parent.name == "motionnospeech"
      text = '<p>' + text + '</p>'
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
  
  def HansardSpeech.clean_content_motion(e)
    # Hmmm. what if there are two para's below? will we get the wrong formatting?
    t = '<p pwmotiontext="moved">'
    e.each_child_node do |e|
      case e.name
      when 'para'
        t << clean_content_para_content(e)
      when 'list'
        t << clean_content_list(e)
      when 'table'
        t << clean_content_table(e)
      else
        throw "Unexpected tag #{e.name}"
      end
    end
    t << '</p>'
    t    
  end
  
  def HansardSpeech.clean_content_any(e, override_type = nil)
    case e.name
    when 'motion'
      clean_content_motion(e)
    when 'amendment', 'quote'
      clean_content_recurse(e, 'italic')
    when 'amendments', 'motionnospeech', 'interjection', 'continue', 'answer', 'question'
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
    when 'graphic'
      clean_content_graphic(e)
    when 'talker', 'name', 'electorate', 'role', 'time.stamp', 'tggroup', 'separator', 'colspec'
      ""
    when 'talk.text', 'debate.text', 'subdebate.text' 
      ""
    when 'Error'
      # Should use @logger.warn here but can't because I don't have access to the logger object. Ho hum.
      puts "Came across an <Error> tag in the XML. That's probably not good. Skipping it."
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

  def strip_tags(doc)
    str=doc.to_s
    str.gsub(/<\/?[^>]*>/, "")
  end

  def HansardSpeech.generic_speaker?(speakername)
    speakername =~ /^(an? )?(honourable|opposition|government) (member|senator)s?$/i
  end

  def name?(name)
    @content.respond_to?(:name) ? name == @content.name : !!@content.at("/#{name}")
  end
end

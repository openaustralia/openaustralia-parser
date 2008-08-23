class HansardSpeech
  attr_reader :logger, :speakername, :aph_id, :interjection
  
  def initialize(content, page, logger = nil)
    @content, @page, @logger = content, page, logger
    # Caching
    @speakername, @aph_id, @interjection = extract_speakername
  end
  
  # The url of a speech is just the url of the page that it comes from
  def permanent_url
    @page.permanent_url
  end
  
  # The time of a speech is just the time of the page that the speech is on
  def time
    @page.time
  end
  
  def extract_speakername
    interjection = false
    speaker_url = nil
    # Try to extract speaker name from talkername tag
    tag = @content.search('span.talkername a').first
    tag2 = @content.search('span.speechname').first
    if tag
      name = tag.inner_html
      speaker_url = tag.attributes['href']
      # Now check if there is something like <span class="talkername"><a>Some Text</a></span> <b>(Some Text)</b>
      tag = @content.search('span.talkername ~ b').first
      # Only use it if it is surrounded by brackets
      if tag && tag.inner_html.match(/\((.*)\)/)
        name += " " + $~[0]
      end
    elsif tag2
      name = tag2.inner_html
    # If that fails try an interjection
    elsif @content.search("div.speechType").inner_html == "Interjection"
      interjection = true
      text = strip_tags(@content.search("div.speechType + *").first)
      m = text.match(/([a-z].*) interjecting/i)
      if m
        name = m[1]
        talker_not_correctly_marked_up = true
      else
        m = text.match(/([a-z].*)—/i)
        if m
          name = m[1]
          talker_not_correctly_marked_up = true
        else
          name = nil
        end
      end
    # As a last resort try searching for interjection text
    else
      m = strip_tags(@content).match(/([a-z].*) interjecting/i)
      if m
        name = m[1]
        talker_not_correctly_marked_up = true
        interjection = true
      else
        m = strip_tags(@content).match(/^([a-z].*?)—/i)
        if m and generic_speaker?(m[1])
          name = m[1]
          talker_not_correctly_marked_up = true
        end
      end
    end
    
    if talker_not_correctly_marked_up
      logger.warn "Speech by #{name} not specified by talkername in #{permanent_url}" unless generic_speaker?(name) || logger.nil?
    end
    [name, extract_aph_id_from_speaker_url(speaker_url), interjection]
  end  

  def clean_content
    doc = Hpricot(@content.to_s)
    talkername_tags = doc.search('span.talkername ~ b ~ *')
    talkername_tags.each do |tag|
      if tag.to_s.chars[0..0] == '—'
        tag.swap(tag.to_s.chars[1..-1])
      end
    end
    talkername_tags = doc.search('span.talkername ~ *')
    talkername_tags.each do |tag|
      if tag.to_s.chars[0..0] == '—'
        tag.swap(tag.to_s.chars[1..-1])
      end
    end
    doc = remove_generic_speaker_names(doc)
    doc.search('div.speechType').remove
    doc.search('span.talkername ~ b').remove
    doc.search('span.talkername').remove
    doc.search('span.talkerelectorate').remove
    doc.search('span.talkerrole').remove
    doc.search('hr').remove
    make_motions_and_quotes_italic(doc)
    remove_subspeech_tags(doc)
    fix_links(doc)
    make_amendments_italic(doc)
    fix_attributes_of_p_tags(doc)
    fix_attributes_of_td_tags(doc)
    fix_motionnospeech_tags(doc)
    # Do pure string manipulations from here
    text = doc.to_s.chars.normalize(:c)
    text = text.gsub(/\(\d{1,2}.\d\d (a|p).m.\)—/, '')
    text = text.gsub('()', '')
    text = text.gsub('<div class="separator"></div>', '')
    # Look for tags in the text and display warnings if any of them aren't being handled yet
    text.scan(/<[a-z][^>]*>/i) do |t|
      m = t.match(/<([a-z]*) [^>]*>/i)
      if m
        tag = m[1]
      else
        tag = t[1..-2]
      end
      allowed_tags = ["b", "i", "dl", "dt", "dd", "ul", "li", "a", "table", "td", "tr", "img"]
      if !allowed_tags.include?(tag) && t != "<p>" && t != '<p class="italic">'
        logger.error "Tag #{t} is present in speech contents: #{text} on #{permanent_url}"
      end
    end
    # Reparse
    doc = Hpricot(text)
    doc.traverse_element do |node|
      text = node.to_s.chars
      if text[0..0] == '—' || text[0..0] == [160].pack('U*')
        node.swap(text[1..-1].to_s)
      end
    end
    doc
  end

  def remove_generic_speaker_names(content)
    if generic_speaker?(speakername) and !interjection
      #remove everything before the first hyphen
      return Hpricot(content.to_s.gsub!(/^<p[^>]*>.*?—/i, "<p>"))
    end
    content
  end

  def fix_motionnospeech_tags(content)
    content.search('div.motionnospeech').wrap('<p></p>')
    replace_with_inner_html(content, 'div.motionnospeech')
    content.search('span.speechname').remove
    content.search('span.speechelectorate').remove
    content.search('span.speechrole').remove
    content.search('span.speechtime').remove
  end
  
  def fix_attributes_of_p_tags(content)
    content.search('p.parabold').wrap('<b></b>')
    content.search('p').each do |e|
      class_value = e.get_attribute('class')
      if class_value == "block" || class_value == "parablock" || class_value == "parasmalltablejustified" ||
          class_value == "parasmalltableleft" || class_value == "parabold" || class_value == "paraheading" || class_value == "paracentre"
        e.remove_attribute('class')
      elsif class_value == "paraitalic"
        e.set_attribute('class', 'italic')
      elsif class_value == "italic" && e.get_attribute('style')
        e.remove_attribute('style')
      end
      e.remove_attribute('style')
    end
  end
  
  def fix_attributes_of_td_tags(content)
    content.search('td').each do |e|
      e.remove_attribute('style')
    end
  end
  
  def fix_links(content)
    content.search('a').each do |e|
      href_value = e.get_attribute('href')
      if href_value.nil?
        # Remove a tags
        e.swap(e.inner_html)
      else
        e.set_attribute('href', URI.join(permanent_url, href_value))
      end
    end
    content.search('img').each do |e|
      e.set_attribute('src', URI.join(permanent_url, e.get_attribute('src')))
    end
    content
  end

  def make_motions_and_quotes_italic(content)
    content.search('div.motion p').set(:class => 'italic')
    replace_with_inner_html(content, 'div.motion')
    content.search('div.quote p').set(:class => 'italic')
    replace_with_inner_html(content, 'div.quote')
    content
  end
  
  def make_amendments_italic(content)
    content.search('div.amendments div.amendment0 p').set(:class => 'italic')
    content.search('div.amendments div.amendment1 p').set(:class => 'italic')
    replace_with_inner_html(content, 'div.amendment0')
    replace_with_inner_html(content, 'div.amendment1')
    replace_with_inner_html(content, 'div.amendments')
    content
  end
  
  def remove_subspeech_tags(content)
    replace_with_inner_html(content, 'div.subspeech0')
    replace_with_inner_html(content, 'div.subspeech1')
    content
  end

  def replace_with_inner_html(content, search)
    content.search(search).each do |e|
      e.swap(e.inner_html)
    end
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

  def generic_speaker?(speakername)
    speakername =~ /^(an? )?(honourable|opposition|government) (member|senator)s?$/i
  end
end

require 'rubygems'
require 'activesupport'

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
    talkername_tag = @content.at('name[@role="display"]') || @content.at('name')
    if talkername_tag.nil?
      p @content
      throw "Couldn't find a speaker"
    end
    aph_id_tag = @content.at('//(name.id)')
    interjection = !@content.at('interjection').nil?
    [talkername_tag.inner_html, aph_id_tag ? aph_id_tag.inner_html : nil, interjection]
  end  

  def HansardSpeech.strip_leading_dash(text)
    if text.chars[0..0] == '—'
      text.chars[1..-1]
    else
      text
    end
  end
  
  def HansardSpeech.clean_content_inline(e)
    if e.attributes.keys == ['ref']
      '<a href="??">' + e.inner_html + '</a>'
    elsif e.attributes.keys == ['font-size']
      e.inner_html
    elsif e.attributes.keys == ['font-style']
      if e.attributes['font-style'] == 'italic'
        '<i>' + e.inner_html + '</i>'
      else
        throw "Unexpected font-style value #{e.attributes['font-style']}"
      end
    elsif e.attributes.keys == ['font-weight']
      if e.attributes['font-weight'] == 'bold'
        '<b>' + e.inner_html + '</b>'
      else
        throw "Unexpected font-weight value #{e.attributes['font-weight']}"
      end
    else
      throw "Unexpected attributes #{e.attributes.keys.join(', ')}"
    end
  end
  
  def HansardSpeech.clean_content_para(e)
    t = ""
    e.children.each do |c|
      if !c.respond_to?(:name)
        t << c.to_s
      elsif c.name == 'inline'
        t << clean_content_inline(c)
      else
        throw "Unexpected tag #{c.name}"
      end
    end
    
    if e.parent.name == 'motion'
      '<p class="italic">' + strip_leading_dash(t) + '</p>'
    elsif ['talk.start', 'speech', 'motionnospeech'].include?(e.parent.name)
      '<p>' + strip_leading_dash(t) + '</p>'
    else
      throw "Unexpected tag #{e.parent.name}"
    end
  end
  
  def HansardSpeech.clean_content_list(e)
    l = ""
    if e.attributes.keys == ['type']
      if ['loweralpha', 'unadorned', 'decimal'].include?(e.attributes['type'])
        e.children.each do |e|
          next unless e.respond_to?(:name)
          if e.name == 'item'
            if e.attributes.keys == ['label']
              l << '<dt>' + e.attributes['label'] + '</dt>'
              d = ""
              e.children.each do |e|
                next unless e.respond_to?(:name)
                if e.name == 'para'
                  d << e.inner_html
                elsif e.name == 'list'
                  d << clean_content_list(e)
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
  
  def HansardSpeech.clean_content_quote(e)
    t = ""
    e.children.each do |e|
      next unless e.respond_to?(:name)
      if e.name == 'para'
        t << '<p class="italic">' + e.inner_html + '</p>'
      elsif e.name == 'list'
        t << clean_content_list(e)
      else
        throw "Unexpected tag #{e.name}"
      end
    end
    t
  end
  
  def HansardSpeech.clean_content_interjection(e)
    c = ""
    e.children.each do |e|
      next unless e.respond_to?(:name)
      if e.name == 'talk.start'
        c << clean_content_talk_start(e)
      else
        throw "Unexpected tag #{e.name}"
      end
    end
    c
  end
  
  def HansardSpeech.clean_content_talk_start(e)
    c = ""
    e.children.each do |e|
      next unless e.respond_to?(:name)
      if e.name == 'para'
        c << clean_content_para(e)
      elsif e.name == 'talker'
        # Skip
      else
        throw "Unexpected tag #{e.name}"
      end
    end
    c
  end
  
  def clean_content
    c = ""
    @content.children.each do |e|
      next unless e.respond_to?(:name)
      if e.name == 'talk.start'
        c << HansardSpeech.clean_content_talk_start(e)
      elsif e.name == 'motion'
        e.children.each do |e|
          next unless e.respond_to?(:name)
          if e.name == 'para'
            c << HansardSpeech.clean_content_para(e)
          elsif e.name == 'list'
            c << HansardSpeech.clean_content_list(e)
          else
            throw "Unexpected tag #{e.name}"
          end
        end
      elsif e.name == 'list'
        c << HansardSpeech.clean_content_list(e)
      elsif e.name == 'para'
        c << HansardSpeech.clean_content_para(e)
      elsif e.name == 'quote'
        c << HansardSpeech.clean_content_quote(e)
      elsif e.name == 'interjection'
        c << HansardSpeech.clean_content_interjection(e)
      elsif ['name', 'electorate', 'role', 'time.stamp', 'inline', 'interjection', 'continue', 'amendments', 'table', 'interrupt'].include?(e.name)
        # Skip
      else
        throw "Unexpected tag #{e.name}"
      end
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

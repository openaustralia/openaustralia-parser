# frozen_string_literal: true

require "additions"
require "name"
require "English"

class HansardSpeech
  attr_reader :logger, :title, :subtitle, :bills, :time, :day, :interjection, :continuation

  def initialize(content:, title:, subtitle:, bills:, time:, day:, logger: nil)
    @content = content
    @title = title
    @subtitle = subtitle
    @bills = bills
    @time = time
    @day = day
    @logger = logger
    @interjection = name?("interjection")
    @continuation = name?("continue")
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
    aph_id_tag = @content.at("//(name.id)")
    aph_id_tag ? aph_id_tag.inner_html : nil
  end

  private

  def speakername_from_tag
    # If there are multiple <name> tags prefer the one with the attribute role='display'
    talkername_tag1 = @content.at("name[@role=metadata]")
    # Only use the 'metadata' if it has brackets in it
    talkername_tag = if talkername_tag1 && talkername_tag1.inner_html =~ /\(.*\)/
                       talkername_tag1
                     else
                       @content.at("name[@role=display]") || @content.at("name")
                     end
    talkername_tag ? talkername_tag.inner_html : nil
  end

  def speakername_from_text
    $LAST_MATCH_INFO[1] if strip_tags(@content) =~ (/^([a-z].*?)( interjecting)?—/i) && HansardSpeech.generic_speaker?($LAST_MATCH_INFO[1])
  end

  public

  def self.strip_leading_dash(text)
    # Unicode Character 'Non-breaking hyphen' (U+2011)
    nbhyphen = [0x2011].pack("U")
    nbsp = [160].pack("U")

    t = text.gsub(nbhyphen, "-")
    # TODO: Not handling dashes and nbsp the same here. Should really be stripping whitespace completely before doing
    # anything for consistency sake.
    if t.strip[0..0] == "—"
      t.sub("—", "")
    # Also remove first non-breaking space (Really should remove them all but we're doing it this way for compatibility
    # with the previous parser
    elsif t[0] == nbsp
      t[1..]
    else
      t
    end
  end

  def self.clean_content_inline(node)
    text = strip_leading_dash(node.inner_html)

    attributes_keys = node.attributes.to_hash.keys
    # Always ignore font-size
    attributes_keys.delete("font-size")

    if attributes_keys.delete("ref")
      # We're going to assume these links always point to Bills.
      link = "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:legislation/billhome/#{node.attributes['ref']}"
      text = "<a href=\"#{link}\">#{text}</a>"
    end

    if attributes_keys.delete("font-style")
      raise "Unexpected font-style value #{node.attributes['font-style']}" unless node.attributes["font-style"] == "italic"

      text = "<i>#{text}</i>"
    end

    if attributes_keys.delete("font-weight")
      raise "Unexpected font-weight value #{e.attributes['font-weight']}" unless node.attributes["font-weight"] == "bold"

      # Workaround for badly marked up content. If a bold item is surrounded in brackets assume it is a name and remove it
      # Alternatively if the bold item is a generic name, remove it as well
      text = if node.inner_html =~ /^\(.*\)$/ || generic_speaker?(node.inner_html)
               ""
             else
               "<b>#{text}</b>"
             end
    end

    if attributes_keys.delete("font-variant")
      case node.attributes["font-variant"]
      when "superscript"
        text = "<sup>#{text}</sup>"
      when "subscript"
        text = "<sub>#{text}</sub>"
      else
        raise "Unexpected font-variant value #{node.attributes['font-variant']}"
      end
    end

    raise "Unexpected attributes #{attributes_keys.join(', ')}" unless attributes_keys.empty?

    # Handle inlines for motionnospeech in a special way
    text = "<p>#{text}</p>" if node.parent.name == "motionnospeech"

    text
  end

  def self.clean_content_graphic(node)
    # TODO: Probably the path needs to be different depending on whether Reps or Senate
    "<img src=\"http://parlinfoweb.aph.gov.au/parlinfo/Repository/Chamber/HANSARDR/#{node.attributes['href']}\"/>"
  end

  # Pass a <para>Some text</para> block. Returns cleaned "Some text"
  def self.clean_content_para_content(node)
    t = +""
    (node.children || []).each do |c|
      t << if c.is_a?(Nokogiri::Text)
             strip_leading_dash(c.to_s)
           else
             clean_content_any(c)
           end
    end
    t
  end

  # Pass a <para>Some text</para> block. Returns cleaned "<p>Some text</p>"
  def self.clean_content_para(node, override_type = nil)
    type = override_type || ""

    case node.attributes["class"]
    when "italic"
      type = "italic"
    when "bold"
      type = "bold"
    end

    case type
    when ""
      "<p>#{clean_content_para_content(node)}</p>"
    when "italic"
      "<p class=\"#{type}\">#{clean_content_para_content(node)}</p>"
    when "bold"
      "<b><p>#{clean_content_para_content(node)}</p></b>"
    else
      raise "Unexpected type value #{type}"
    end
  end

  def self.clean_content_item(node)
    d = +""
    node.each_child_node do |f|
      case f.name
      when "para"
        d << clean_content_para_content(f)
      when "list"
        d << clean_content_list(f)
      when "table"
        d << clean_content_table(f)
      else
        raise "Unexpected tag #{f.name}"
      end
    end
    if node.has_attribute?("label")
      "<dt>#{node.attributes['label']}</dt><dd>#{d}</dd>"
    else
      "<li>#{d}</li>"
    end
  end

  def self.clean_content_list(node)
    # We figure out whether to generate a <dl> or <ul> based on whether the child tags all have a 'label' attribute or not
    label = node.at("> item").has_attribute?("label") if node.at("> item")
    # Check that all the children are consistent
    node.search("> item").each do |c|
      raise "Children of <list> are using the 'label' attribute inconsistently" if c.has_attribute?("label") != label
    end

    if label
      "<dl>#{clean_content_recurse(node)}</dl>"
    else
      "<ul>#{clean_content_recurse(node)}</ul>"
    end
  end

  def self.clean_content_entry(node, override_type = nil)
    attributes = 'valign="top"'
    attributes << " colspan=\"#{node.attributes['colspan']}\"" if node.attributes["colspan"] && node.attributes["colspan"] != ""
    "<td #{attributes}>#{clean_content_recurse(node, override_type)}</td>"
  end

  def self.clean_content_table(node, override_type = nil)
    # Not sure if I really should put border="0" here. Hmmm...
    "<table border=\"0\">#{clean_content_recurse(node, override_type)}</table>"
  end

  def self.clean_content_motion(node)
    # Hmmm. what if there are two para's below? will we get the wrong formatting?
    t = +'<p pwmotiontext="moved">'
    node.each_child_node do |f|
      case f.name
      when "para"
        t << clean_content_para_content(f)
      when "list"
        t << clean_content_list(f)
      when "table"
        t << clean_content_table(f)
      else
        raise "Unexpected tag #{f.name}"
      end
    end
    t << "</p>"
    t
  end

  def self.clean_content_any(node, override_type = nil)
    case node.name
    when "motion"
      clean_content_motion(node)
    when "amendment", "quote"
      clean_content_recurse(node, "italic")
    when "talk.start", "amendments", "motionnospeech", "interjection", "continue", "answer", "question"
      clean_content_recurse(node)
    when "tgroup", "thead", "tbody"
      clean_content_recurse(node, override_type)
    when "para"
      clean_content_para(node, override_type)
    when "list"
      clean_content_list(node)
    when "table"
      clean_content_table(node, override_type)
    when "inline"
      clean_content_inline(node)
    when "interrupt"
      "<b>#{clean_content_recurse(node)}</b>"
    when "row"
      "<tr>#{clean_content_recurse(node, override_type)}</tr>"
    when "entry"
      clean_content_entry(node, override_type)
    when "item"
      clean_content_item(node)
    when "graphic"
      clean_content_graphic(node)
    when "talker", "name", "electorate", "role", "time.stamp", "tggroup", "separator", "colspec", "talk.text", "debate.text", "subdebate.text"
      ""
    when "Error"
      # Should use @logger.warn here but can't because I don't have access to the logger object. Ho hum.
      puts "Came across an <Error> tag in the XML. That's probably not good. Skipping it."
      ""
    else
      raise "Unexpected tag #{node.name}"
    end
  end

  def self.clean_content_recurse(node, override_type = nil)
    t = +""
    node.each_child_node do |f|
      t << clean_content_any(f, override_type)
    end
    t
  end

  def clean_content
    Nokogiri.XML(HansardSpeech.clean_content_any(@content))
  end

  def strip_tags(doc)
    str = doc.to_s
    str.gsub(%r{</?[^>]*>}, "")
  end

  def self.generic_speaker?(speakername)
    speakername =~ /^(an? )?(honourable|opposition|government) (member|senator)s?$/i
  end

  def name?(name)
    @content.is_a?(Nokogiri::Text) ? !!@content.at("/#{name}") : name == @content.name
  end
end

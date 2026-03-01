# frozen_string_literal: true

require "hpricot_additions"
require "htmlentities"
require "section"

class Speech < Section
  attr_accessor :speaker, :content, :interjection, :continuation,
                :word_count_for_continuations
  attr_reader :duration

  def initialize(speaker:, time:, url:, count:, date:, house:, logger: nil)
    @speaker = speaker
    @content = []
    @duration = 0
    @word_count_for_continuations = 0
    super(time: time, url: url, count: count, date: date, house: house, logger: logger)
  end

  def output(builder)
    time = @time.nil? ? "unknown" : @time
    # Format content for output - handle arrays of nodes
    content_output = if @content.is_a?(Array)
                       @content.map do |node|
                         # Use to_s for elements to output HTML
                         node.to_s
                       end.join
                     else
                       @content.respond_to?(:inner_html) ? @content.inner_html : @content.to_s
                     end
    
    # Get text content for validation
    content_text = if @content.is_a?(Array)
                     @content.map { |node| node.respond_to?(:inner_text) ? node.inner_text : node.to_s }.join
                   else
                     @content.respond_to?(:inner_text) ? @content.inner_text : @content.to_s
                   end
    
    if @logger && content_text.strip == ""
      if @speaker.nil?
        @logger.error "#{@date} #{@house}: Empty speech in procedural text"
      else
        @logger.error "#{@date} #{@house}: Empty speech by #{@speaker.person.name.full_name}"
      end
    end
    speaker_attributes = if @speaker
                           { speakername: @speaker.name.full_name,
                             speakerid: @speaker.id }
                         else
                           { nospeaker: "true" }
                         end
    builder.speech(
      speaker_attributes.merge({ time: time, url: quoted_url, id: id, talktype: talk_type,
                                 approximate_duration: @duration.to_i, approximate_wordcount: words })
    ) { builder << content_output }
  end

  def append_to_content(content)
    # Put entities back into the content so that, for instance, '&' becomes '&amp;'
    # Since we are outputting XML rather than HTML in order to save us the trouble of putting the HTML entities in the XML
    # we are only encoding the basic XML entities
    coder = HTMLEntities.new
    
    # If content is a Document node, extract the body element's children
    if content.is_a?(Nokogiri::HTML4::Document) || content.is_a?(Nokogiri::XML::Document)
      body = content.at_xpath('//body')
      if body
        # Get the children of the body (the actual content elements)
        children_to_add = body.children.to_a
      else
        # Fallback to all children if no body
        children_to_add = content.children.to_a
      end
    elsif content.is_a?(Array)
      children_to_add = content
    else
      children_to_add = [content]
    end
    
    # Traverse and encode text nodes
    children_to_add.each do |node|
      node.traverse_text { |text| text.swap(coder.encode(text, :basic)) } if node.respond_to?(:traverse_text)
    end
    
    # Append to stored content (flatten in case we get nested arrays)
    @content += children_to_add.flatten
  end

  def talk_type
    if @interjection
      "interjection"
    elsif @continuation
      "continuation"
    else
      "speech"
    end
  end

  def duration=(duration_estimate)
    # Cleanup up durations less than zero
    duration_estimate = 0 if duration_estimate.negative?
    if !interjection && !continuation
      # If the duration seems to be off the word count estimate by more than 10
      # minutes, fallback to the wordcount estimate
      duration_from_wordcount = ((words + word_count_for_continuations) / 120).round * 60
      duration_estimate = duration_from_wordcount if (duration_estimate - duration_from_wordcount).abs > 600
    end
    @duration = duration_estimate
  end

  # Returns adjournment time if the debate was adjourned during the speech
  def adjournment
    match = @content.to_s.match(/adjourned at (\d+:\d\d)/mi)
    match && to_time(match[1])
  end

  # Returns a word count of the content text
  def words
    # Add newlines between p tags so the last and first words of paragraphs are
    # split properly
    html = if @content.is_a?(Array)
             @content.map(&:to_s).join
           else
             @content.inner_html
           end
    html = html.gsub(%r{</p>}, "</p>\n")
    Nokogiri::HTML(html).inner_text.split.count
  end
end

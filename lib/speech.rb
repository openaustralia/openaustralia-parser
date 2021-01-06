# frozen_string_literal: true

require "hpricot"
require "htmlentities"
require "section"

class Speech < Section
  attr_accessor :speaker, :content, :interjection, :continuation,
                :word_count_for_continuations
  attr_reader :duration

  def initialize(speaker, time, url, count, date, house, logger = nil)
    @speaker = speaker
    @content = Hpricot::Elements.new
    @duration = 0
    @word_count_for_continuations = 0
    super(time, url, count, date, house, logger)
  end

  def output(x)
    time = @time.nil? ? "unknown" : @time
    if @logger && @content.inner_text.strip == ""
      if @speaker.nil?
        @logger.error "#{@date} #{@house}: Empty speech in procedural text"
      else
        @logger.error "#{@date} #{@house}: Empty speech by #{@speaker.person.name.full_name}"
      end
    end
    speaker_attributes = @speaker ? { speakername: @speaker.name.full_name, speakerid: @speaker.id } : { nospeaker: "true" }
    x.speech(speaker_attributes.merge({
                                        time: time, url: quoted_url, id: id, talktype: talk_type,
                                        approximate_duration: @duration.to_i, approximate_wordcount: words
                                      })) { x << @content.to_s }
  end

  def append_to_content(content)
    # Put entities back into the content so that, for instance, '&' becomes '&amp;'
    # Since we are outputting XML rather than HTML in order to save us the trouble of putting the HTML entities in the XML
    # we are only encoding the basic XML entities
    coder = HTMLEntities.new
    content.traverse_text do |text|
      text.swap(coder.encode(text, :basic))
    end
    # Append to stored content
    if content.is_a?(Array)
      @content += content
    else
      @content << content
    end
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
    duration_estimate = 0 if duration_estimate < 0
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
    html = @content.inner_html.gsub(%r{</p>}, "</p>\n")
    Hpricot(html).inner_text.split.count
  end
end

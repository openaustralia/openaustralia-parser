# frozen_string_literal: true

require "nokogiri"
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
    content_text = @content.map(&:to_s).join
    if @logger && Nokogiri::HTML(content_text).text.strip == ""
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
    ) { builder << content_text }
  end

  def append_to_content(content)
    # Handle traversing text nodes for Nokogiri
    if content.respond_to?(:xpath)
      # It's a Nokogiri node. If this is an HTML document, keep only the body content.
      content = content.at("body") if content.at("body")
      content = content.children.to_a
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
    duration_estimate = 0 if duration_estimate.negative?
    if !interjection && !continuation
      # If the duration seems to be off the word count estimate by more than 10
      # minutes, fallback to the wordcount estimate
      duration_from_wordcount = ((words + word_count_for_continuations) / 120).round * 60
      if (duration_estimate - duration_from_wordcount).abs > 600
        duration_estimate = duration_from_wordcount
      end
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
    html = @content.map(&:to_s).join.gsub(%r{</p>}, "</p>\n")
    Nokogiri::HTML(html).text.split.count
  end
end

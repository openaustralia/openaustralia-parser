# frozen_string_literal: true

require "heading"
require "speech"
require "division"
require "count"

# Holds the data for debates on one day
# Also knows how to output the XML data for that
class Debates
  attr_reader :items

  def initialize(date, house, logger = nil)
    @date = date
    @house = house
    @logger = logger
    @title = ""
    @subtitle = ""
    @items = []
    @count = Count.new
    @division_count = 1
    @latest_major_heading = nil
    @latest_minor_heading = nil
  end

  def add_heading(newtitle, newsubtitle, url, bills)
    # Only add headings if they have changed
    if newtitle != @title
      @latest_major_heading = MajorHeading.new(newtitle, @count.clone, url, bills, @date, @house)
      @count.increment_minor
    end
    if newtitle != @title || newsubtitle != @subtitle
      @latest_minor_heading = MinorHeading.new(newsubtitle, @count.clone, url, bills, @date, @house)
      @count.increment_minor
    end
    @title = newtitle
    @subtitle = newsubtitle
  end

  def add_heading_for_real
    if @latest_major_heading
      @items << @latest_major_heading
      @latest_major_heading = nil
    end
    return unless @latest_minor_heading

    @items << @latest_minor_heading
    @latest_minor_heading = nil
  end

  def increment_minor_count
    @count.increment_minor
  end

  def increment_major_count
    @count.increment_major
  end

  def increment_division_count
    @division_count += 1
  end

  def add_speech(speaker, time, url, content, interjection: false, continuation: false)
    add_heading_for_real

    # Only add new speech if the speaker has changed
    if !@items.last.is_a?(Speech) || speaker != last_speaker
      speech = Speech.new(speaker, time, url, @count.clone, @date, @house, @logger)
      speech.interjection = interjection
      speech.continuation = continuation
      @items << speech
    end
    @items.last.append_to_content(content)
  end

  def add_division(yes, no, yes_tellers, no_tellers, pairs, time, url, bills)
    add_heading_for_real

    @items << Division.new(yes, no, yes_tellers, no_tellers, pairs, time, url, bills, @count.clone, @division_count, @date, @house, @logger)
    increment_division_count
  end

  def last_speaker
    @items.last.speaker if @items.last.respond_to?(:speaker)
  end

  def output_builder(x)
    x.instruct!
    x.debates do
      @items.each { |i| i.output(x) }
    end
  end

  def calculate_speech_durations
    @items.each_with_index do |section, index|
      next unless section.is_a?(Speech)

      unless section.time
        section.duration = 0
        next
      end

      # Interjections are skipped
      next if section.interjection || section.continuation

      # if this speech ends with an adjournment, use that as the end time
      adjournment = section.adjournment
      if adjournment
        section.duration = adjournment - section.to_time
        next
      end

      # Scan ahead looking for the next section (skipping sections without time
      # or interjections or continuations). Also keep track of how many words
      # were used in continuations
      next_section = @items[(index + 1)..].detect do |next_item|
        section.word_count_for_continuations += next_item.words if next_item.is_a?(Speech) && next_item.continuation
        next_item.is_a?(Speech) && next_item.time && !next_item.interjection && !next_item.continuation
      end

      # Calculate the duration if a next section is found, otherwise, stop
      section.duration = if next_section
                           next_section.to_time - section.to_time
                         else
                           0
                         end
    end
  end

  def output(xml_filename)
    xml = File.open(xml_filename, "w")
    x = Builder::XmlMarkup.new(target: xml, indent: 1)
    output_builder(x)

    xml.close
  end
end

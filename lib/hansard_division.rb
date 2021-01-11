# frozen_string_literal: true

require "English"

class HansardDivision
  attr_reader :title, :subtitle, :bills

  def initialize(content, title, subtitle, bills, day)
    @content = content
    @title = title
    @subtitle = subtitle
    @bills = bills
    @day = day
  end

  def permanent_url
    @day.permanent_url
  end

  # Return an array of the names of people that voted yes
  def yes
    (add_speaker?(:yes) ? raw_yes.push(speaker) : raw_yes).map { |text| HansardDivision.name(text) }
  end

  # And similarly for the people that voted no
  def no
    (add_speaker?(:no) ? raw_no.push(speaker) : raw_no).map { |text| HansardDivision.name(text) }
  end

  def tied?
    raw_yes.count == raw_no.count
  end

  def passed?
    case @content.at("(division.result)").inner_text
    when /casting vote with the ayes/, /agreed to/
      true
    when /casting vote with the noes/, /negatived/, /was not carried/
      false
    else
      raise "Could not determine division result"
    end
  end

  def pairs
    names = @content.search("(division.data) > pairs > names > name").map(&:inner_html)
    raise "Not an even number of people in the pairs voting" if names.size.odd?

    # Format the flat list of names into pairs (assuming that the people in pairs appear consecutively)
    pairs = []
    names.each_slice(2) { |p| pairs << p }
    pairs
  end

  def yes_tellers
    raw_yes.find_all { |text| HansardDivision.teller?(text) }.map { |text| HansardDivision.name(text) }
  end

  def no_tellers
    raw_no.find_all { |text| HansardDivision.teller?(text) }.map { |text| HansardDivision.name(text) }
  end

  def time
    tag = @content.at("(division.header) > (time.stamp)")
    time = tag.inner_html if tag
    # if no timestamp, fallback to extracting out of preamble
    if !time && (header = @content.at("(division.header)"))
      results = header.inner_html.match(/\[(..:..)\]/)
      time = results[1] if results
    end
    time
  end

  def speaker
    # There's a slight difference between older and newer XML
    header_speaker_text = if @content.at("(division) > (para)")
                            @content.at("(division) > (para)").inner_text
                          else
                            @content.at("(division.header)").inner_text
                          end

    raise("Speaker not found") unless header_speaker_text.gsub("\342\200\224",
                                                               "&#x2014;") =~ /(Speaker|President)&#x2014;(.*)\)/

    speaker_name = Name.title_first_last($LAST_MATCH_INFO[2])
    "#{speaker_name.last}, " + (speaker_name.initials.empty? ? speaker_name.first : speaker_name.initials)
  end

  def self.name(text)
    text =~ /^(.*)\*$/ ? $LAST_MATCH_INFO[1].strip : text
  end

  def self.teller?(text)
    text =~ /^(.*)\*$/
  end

  private

  def add_speaker?(to_vote)
    case to_vote
    when :yes
      @day.add_speaker_to_tied_votes? && tied? && passed?
    when :no
      @day.add_speaker_to_tied_votes? && tied? && !passed?
    end
  end

  def raw_yes
    @content.search("(division.data) > ayes > names > name").map(&:inner_html)
  end

  def raw_no
    @content.search("(division.data) > noes > names > name").map(&:inner_html)
  end
end

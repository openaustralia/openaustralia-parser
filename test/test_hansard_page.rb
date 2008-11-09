#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/../lib"

require "test/unit"

require "hansard_page"
require 'rubygems'
require 'hpricot'

class TestHansardPage < Test::Unit::TestCase
  def setup
    @speaker = HansardPage.new([Hpricot.XML(
			'<speech>
			  <talk.start></talk.start>
			  <interjection></interjection>
			  <para></para>
			</speech>').at('speech')], nil, nil, nil)
		
		# This has an interjection within a speech
		@interjection = HansardPage.new([Hpricot.XML('
  <speech>
    <talk.start>
      <talker>
        <name role="metadata">Abbott, Tony, MP</name>
        <name.id>EZ5</name.id>
        <name role="display">Mr ABBOTT</name>
      </talker>
      <para>Some talk</para>
    </talk.start>
    <para>Some more talk</para>
    <interjection>
      <talk.start>
        <talker>
          <name.id>10000</name.id>
          <name role="metadata">Somlyay, Alex (The DEPUTY SPEAKER)</name>
          <name role="display">The DEPUTY SPEAKER</name>
        </talker>
        <para>An interjection</para>
      </talk.start>
    </interjection>
    <para>And continue on</para>
  </speech>
    ').at('speech')], nil, nil, nil)
  end
  
  def test_speaker
    # We're only using the <speech> data for the time being
    assert_equal(3, @speaker.speeches.size)
  end
  
  #def test_interjection_within_speech
  #  # The contents of <speech> tag should get split into 3 separate speeches as the initial bit of the speech, the interjection and 
  #  # then the continuation
  #  assert_equal([["Mr ABBOTT", "EZ5", false], ["The DEPUTY SPEAKER", "10000", true], ["Mr ABBOTT", "EZ5", false]],
  #    @interjection.speeches.map{|s| s.extract_speakername})
  #end
end
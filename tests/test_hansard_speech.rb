#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/../lib"

require "test/unit"

require "hansard_speech"
require 'rubygems'
require 'hpricot'

class TestHansardSpeech < Test::Unit::TestCase
  def test_speakername_in_speech
    speech = HansardSpeech.new(Hpricot.XML('
		<speech>
			<talk.start>
				<talker>
					<name role="metadata">Rudd, Kevin, MP</name>
					<name.id>83T</name.id>
					<name role="display">Mr RUDD</name>
				</talker>
			</talk.start>
		</speech>'), nil)
		assert_equal(["Mr RUDD", "83T", false], speech.extract_speakername)
	end
	
	def test_speakername_in_motionnospeech
	  speech = HansardSpeech.new(Hpricot.XML('<motionnospeech><name>Mr BILLSON</name></motionnospeech>'), nil)
	  assert_equal(["Mr BILLSON", nil, false], speech.extract_speakername)
	end
	
	def test_speakername_in_interjection
	  speech = HansardSpeech.new(Hpricot.XML('
	  <interjection>
			<talk.start>
				<talker>
					<name.id>10000</name.id>
					<name role="metadata">SPEAKER, The</name>
					<name role="display">The SPEAKER</name>
				</talker>
			</talk.start>
		</interjection>'), nil)
		assert_equal(["The SPEAKER", "10000", true], speech.extract_speakername)
  end
  
  def test_clean_content1
    speech = HansardSpeech.new(Hpricot.XML('<speech><talk.start><para>—I move:</para></talk.start></speech>').at('speech'), nil)
		expected_result = '<p>I move:</p>'
		assert_equal(expected_result, speech.clean_content.to_s)
  end
end
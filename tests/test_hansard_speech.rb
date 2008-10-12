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
    speech = HansardSpeech.new(Hpricot.XML('<speech><talk.start><para>—I move:</para></talk.start></speech>').at('//(talk.start)'), nil)
		expected_result = '<p>I move:</p>'
		assert_equal(expected_result, speech.clean_content.to_s)
  end
  
  def test_clean_content_on_motion
    content = '<motion><para><inline font-size="9pt">Some intro</inline></para><list type="loweralpha"><item label="(a)"><para>Point a</para></item><item label="(b)"><para>Point b</para></item></list></motion>'		
		expected_result = '<p class="italic">Some intro</p><dl><dt>(a)</dt><dd>Point a</dd><dt>(b)</dt><dd>Point b</dd></dl>'
		assert_equal(expected_result, HansardSpeech.new(Hpricot.XML(content).at('motion'), nil).clean_content.to_s)
  end
  
  def test_clean_content_inline
    content = '<inline font-size="9.5pt">Some text</inline>'
    expected = 'Some text'
    assert_equal(expected, HansardSpeech.clean_content_inline(Hpricot.XML(content).at('inline')))
    
    content = '<inline ref="R2715">Some text</inline>'
    expected = '<a href="??">Some text</a>'
    assert_equal(expected, HansardSpeech.clean_content_inline(Hpricot.XML(content).at('inline')))
    
    content = '<inline font-style="italic">Some text</inline>'
    expected = '<i>Some text</i>'
    assert_equal(expected, HansardSpeech.clean_content_inline(Hpricot.XML(content).at('inline')))
    
    content = '<inline font-weight="bold">Some text</inline>'
    expected = '<b>Some text</b>'
    assert_equal(expected, HansardSpeech.clean_content_inline(Hpricot.XML(content).at('inline')))    
  end
  
  def test_clean_content_list
    content = '<list type="unadorned"><item label=""><para>Some text</para><list type="loweralpha"><item label="(b)"><para>Section b</para></item></list></item></list>'
    expected = '<dl><dt></dt><dd>Some text<dl><dt>(b)</dt><dd>Section b</dd></dl></dd></dl>'
    assert_equal(expected, HansardSpeech.clean_content_list(Hpricot.XML(content).at('list')))
  end
  
  def test_clean_content_para
    content = '<speech><para class="block">Some text</para></speech>'
    expected = '<p>Some text</p>'
    assert_equal(expected, HansardSpeech.clean_content_para(Hpricot.XML(content).at('para')))
    speech = HansardSpeech.new(Hpricot.XML(content).at('para'), nil)
    assert_equal(expected, speech.clean_content.to_s)
  end
  
  def test_clean_content_inline_in_brackets
    # This happens when a name hasn't been marked up correctly
    content = '<inline font-weight="bold">(A name)</inline>'
    assert_equal('', HansardSpeech.clean_content_inline(Hpricot.XML(content).at('inline')))
  end
  
  def test_clean_content_para_with_badly_marked_up_speaker
    content = '<speech><para><inline font-weight="bold">(A name)</inline>—Some text</para></speech>'
    expected = '<p>Some text</p>'
    assert_equal(expected, HansardSpeech.clean_content_para(Hpricot.XML(content).at('para')))
  end
  
  # Only remove the first non-breaking-space from paragraph for compatibility with previous parser
  def test_clean_content_para_with_non_breaking_spaces
    nbsp = [160].pack('U')
    content = "<speech><para class=\"subsection\">#{nbsp}#{nbsp}#{nbsp} Foo</para></speech>"
    expected = "<p>#{nbsp}#{nbsp} Foo</p>"
    assert_equal(expected.chars.normalize, HansardSpeech.clean_content_para(Hpricot.XML(content).at('para')).chars.normalize)
  end
end
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
    
    content = '<inline font-style="italic">Some text</inline>'
    expected = '<i>Some text</i>'
    assert_equal(expected, HansardSpeech.clean_content_inline(Hpricot.XML(content).at('inline')))
    
    content = '<inline font-weight="bold">Some text</inline>'
    expected = '<b>Some text</b>'
    assert_equal(expected, HansardSpeech.clean_content_inline(Hpricot.XML(content).at('inline')))    
  end
  
  def test_link_to_bills
    content = '<inline ref="R2715">Some text</inline>'
    expected = '<a href="http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:legislation/billhome/R2715">Some text</a>'
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
  
  def test_clean_content_para2
    content = '<speech><para>A <inline font-size="12pt">B </inline><inline font-style="italic" font-size="12pt">C</inline><inline font-size="12pt"> D</inline>E</para></speech>'
    expected = '<p>A B <i>C</i> DE</p>'
    assert_equal(expected, HansardSpeech.clean_content_para(Hpricot.XML(content).at('para')))
  end
  
  def test_clean_content_inline_in_brackets
    # This happens when a name hasn't been marked up correctly
    content = '<inline font-weight="bold">(A name)</inline>'
    assert_equal('', HansardSpeech.clean_content_inline(Hpricot.XML(content).at('inline')))
  end
  
  def test_clean_content_para_with_badly_marked_up_speaker
    # For a name in brackets
    content = '<speech><para><inline font-weight="bold">(A name)</inline>—Some text</para></speech>'
    expected = '<p>Some text</p>'
    assert_equal(expected, HansardSpeech.clean_content_para(Hpricot.XML(content).at('para')))
    
    # For a 'generic name' that isn't in brackets
    content = '<speech><para><inline font-weight="bold">Honourable members</inline>Hear, hear!</para></speech>'
    expected = '<p>Hear, hear!</p>'
    assert_equal(expected, HansardSpeech.clean_content_para(Hpricot.XML(content).at('para')))
    
    # For a bit of text that is bold but isn't a generic name it shouldn't delete it
    content = '<speech><para><inline font-weight="bold">Some text in bold</inline>Blah blah</para></speech>'
    expected = '<p><b>Some text in bold</b>Blah blah</p>'
    assert_equal(expected, HansardSpeech.clean_content_para(Hpricot.XML(content).at('para')))    
  end
  
  # Only remove the first non-breaking-space from paragraph for compatibility with previous parser
  def test_clean_content_para_with_non_breaking_spaces
    nbsp = [160].pack('U')
    content = "<speech><para>#{nbsp}#{nbsp}#{nbsp} Foo</para></speech>"
    expected = "<p>#{nbsp}#{nbsp} Foo</p>"
    assert_equal(expected.chars.normalize, HansardSpeech.clean_content_para(Hpricot.XML(content).at('para')).chars.normalize)
  end
  
  def test_clean_content_table
    content_heading = '<thead><row><entry><para>1</para></entry><entry><para>2</para></entry></row></thead>'
    content_row1 = '<row><entry><para>3</para></entry><entry><para>4</para></entry></row>'
    content_row2 = '<row><entry><para>5</para></entry><entry><para>6</para></entry></row>'
    content = "<table><tgroup><colspec/><colspec/>#{content_heading}<tbody>#{content_row1}#{content_row2}</tbody></tgroup></table>"
    
    # HACK: 'border=0' is in output table tag (For compatibility with output of previous parser)
    expected = '<table border="0"><tr><td><p>1</p></td><td><p>2</p></td></tr><tr><td><p>3</p></td><td><p>4</p></td></tr><tr><td><p>5</p></td><td><p>6</p></td></tr></table>'
    assert_equal(expected, HansardSpeech.clean_content_table(Hpricot.XML(content).at('table')))
  end
  
  def test_clean_non_breaking_dashes
    # Unicode Character 'Non-breaking hyphen' (U+2011)
    nbhyphen = [0x2011].pack('U')

    content = "<speech><para>Auditor#{nbhyphen}General</para></speech>"
    expected = "<p>Auditor-General</p>"

    assert_equal(expected, HansardSpeech.clean_content_para(Hpricot.XML(content).at('para')))
  end
end
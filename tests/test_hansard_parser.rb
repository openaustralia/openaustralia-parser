#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'test/unit'
require 'hansard_parser'
require 'rubygems'
require 'hpricot'
require 'people'

class TestHansardParser < Test::Unit::TestCase
  def setup
    doc = Hpricot('<a href="http://website/bar/blah.html">[Permalink]</a>')
    @page = HansardPage.new(doc, nil, nil, nil)
  end
  
  #def test_permanent_url
  #  assert_equal("http://website/bar/blah.html", @page.permanent_url)
  #end
  
  #def test_make_motions_and_quotes_italic
  #  doc = Hpricot('<p>I move:</p><div class="motion"><p>Some text</p></div>')
  #  assert_equal('<p>I move:</p><p class="italic">Some text</p>', HansardSpeech.new(doc, @page).clean_content.to_s)
  #end
  
  #def test_remove_subspeech_tags
  #  doc = Hpricot('<div class="subspeech0"><p>Some Text</p></div><div class="subspeech0"><p>Some Other Text</p></div>')
  #  assert_equal('<p>Some Text</p><p>Some Other Text</p>', HansardSpeech.new(doc, @page).clean_content.to_s)
  #end

  #def test_fix_links_relative_link
  #  doc = Hpricot('<p>The <a href="foo.html">Link Text</a> Some Text</p>')
  #  assert_equal('<p>The <a href="http://website/bar/foo.html">Link Text</a> Some Text</p>', HansardSpeech.new(doc, @page).clean_content.to_s)
  #end
  
  #def test_fix_links_absolute_link
  #  doc = Hpricot('<p>The <a href="http://anothersite/foo.html">Link Text</a> Some Text</p>')
  #  assert_equal('<p>The <a href="http://anothersite/foo.html">Link Text</a> Some Text</p>', HansardSpeech.new(doc, @page).clean_content.to_s)
  #end
  
  #def test_fix_links_on_image
  #  doc = Hpricot('<p>The <img src="/parlinfo/Repository/Chamber/HANSARDR/5320M_image002.jpg" /> Some Text</p>')
  #  assert_equal('<p>The <img src="http://website/parlinfo/Repository/Chamber/HANSARDR/5320M_image002.jpg" /> Some Text</p>', HansardSpeech.new(doc, @page).clean_content.to_s)
  #end
  
  #def test_fix_links_empty_a_tag
  #  doc = Hpricot('<p>The <a>Link Text</a> Some Text</p>')
  #  assert_equal('<p>The Link Text Some Text</p>', HansardSpeech.new(doc, @page).clean_content.to_s)
  #end
  
  #def test_make_amendments_italic
  #  doc = Hpricot('<div class="amendments"><div class="amendment0"><p class="paraParlAmend">Some Text</p></div><div class="amendment1"><p class="paraParlAmend">Some more text</p></div></div>')
  #  assert_equal('<p class="italic">Some Text</p><p class="italic">Some more text</p>', HansardSpeech.new(doc, @page).clean_content.to_s)
  #end
  
  #def test_fix_attributes_of_p_tags_block
  #  doc = Hpricot('<p class="block">Some Text</p>')
  #  assert_equal('<p>Some Text</p>', HansardSpeech.new(doc, @page).clean_content.to_s)
  #end
  
  #def test_fix_attributes_of_p_tags_parablock
  #  doc = Hpricot('<p class="parablock">Some Text</p>')
  #  assert_equal('<p>Some Text</p>', HansardSpeech.new(doc, @page).clean_content.to_s)
  #end

  #def test_fix_attributes_of_p_tags_paraitalic
  #  doc = Hpricot('<p class="paraitalic">Some Text</p>')
  #  assert_equal('<p class="italic">Some Text</p>', HansardSpeech.new(doc, @page).clean_content.to_s)
  #end
  
  #def test_fix_attributes_of_p_tags_parasmalltablejustified
  #  doc = Hpricot('<p class="parasmalltablejustified">Some Text</p>')
  #  assert_equal('<p>Some Text</p>', HansardSpeech.new(doc, @page).clean_content.to_s)
  #end
  
  #def test_fix_attributes_of_p_tags_text_indent
  #  doc = Hpricot('<p class="italic" style="text-indent: 0;">Some Text</p>')
  #  assert_equal('<p class="italic">Some Text</p>', HansardSpeech.new(doc, @page).clean_content.to_s)
  #end
  
  #def test_fix_attributes_of_p_tags_parasmalltableleft
  #  doc = Hpricot('<p class="parasmalltableleft">Some Text</p>')
  #  assert_equal('<p>Some Text</p>', HansardSpeech.new(doc, @page).clean_content.to_s)
  #end
  
  #def test_fix_attributes_of_p_tags_paraheading
  #  doc = Hpricot('<p class="paraheading">Some Text</p>')
  #  assert_equal('<p>Some Text</p>', HansardSpeech.new(doc, @page).clean_content.to_s)
  #end
  
  #def test_fix_attributes_of_td_tags_style
  #  doc = Hpricot('<td style="foo">Some Text</td>')
  #  assert_equal('<td>Some Text</td>', HansardSpeech.new(doc, @page).clean_content.to_s)
  #end
  
  #def test_fix_attributes_of_p_tags_parabold
  #  doc = Hpricot('<p class="parabold">Some Text</p>')
  #  assert_equal('<b><p>Some Text</p></b>', HansardSpeech.new(doc, @page).clean_content.to_s)
  #end
  
  #def test_fix_motionnospeech_tags
  #  doc = Hpricot(
#'<div class="motionnospeech"><span class="speechname">Mr ABBOTT</span><span class="speechelectorate">(Warringah</span><span class="speechrole">Leader of the House)</span><span class="speechtime"></span>Some Text</div>')
  #  assert_equal('<p>Some Text</p>', HansardSpeech.new(doc, @page).clean_content.to_s)
  #end
  
  #def test_extract_speakername
  #  good_form1 = '<p><span class="talkername"><a HREF="view_document.aspx?TABLE=biogs&ID=1023">Mr Hunt</a></span></p>'
  #  good_form2 = '<p><span class="talkername"><a>The Deputy Speaker</a></span><b>(Mr Hunt)</p>'
  #  good_form3 = '<div class="subspeech1"><div class="speechType">Interjection</div><p> <i>Mr Smith interjecting</i>—</p></div>'
  #  good_form4 = '<div class="subspeech1"><div class="speechType">Interjection</div><p> <i>Ms Johnson</i>—</p></div>'
  #  good_form5 = '<div class="subspeech1"><div class="speechType">Continue</div><p><span class="talkername"><a href="blah">Mr BAIRD</a></span>—Some words</p></div>'
  #  good_form6 = '<p><b>Honourable members</b>—Hear, hear!</p>'
  #  good_form7 = '<p><b>Honourable members</b>—My <b>Honourable members</b>—I beseech thee to not use greedy regexes!</p>'
  #  good_form8 = '<p class="paraitalic">Honourable members interjecting—</p>'
  #  good_form9 = '<p class="block"><b>Opposition members</b>—Hear, hear!</p>'
	#	
	#	bad_form1 = '<p class="block">Some words.</p>'
	#	bad_form2 = '<p>Mr Hunt</p>'
	#	
  #  assert_equal(["Mr Hunt", 1023, false], HansardSpeech.new(Hpricot(good_form1), @page).extract_speakername)
  #  assert_equal(["The Deputy Speaker (Mr Hunt)", nil, false], HansardSpeech.new(Hpricot(good_form2), @page).extract_speakername)
  #  assert_equal(["Mr Smith", nil, true], HansardSpeech.new(Hpricot(good_form3), @page).extract_speakername)
  #  assert_equal(["Ms Johnson", nil, true], HansardSpeech.new(Hpricot(good_form4), @page).extract_speakername)
  #  assert_equal(["Mr BAIRD", nil, false], HansardSpeech.new(Hpricot(good_form5), @page).extract_speakername)
  #  assert_equal(["Honourable members", nil, false], HansardSpeech.new(Hpricot(good_form6), @page).extract_speakername)
  #  assert_equal(["Honourable members", nil, false], HansardSpeech.new(Hpricot(good_form7), @page).extract_speakername)
  #  assert_equal(["Honourable members", nil, true], HansardSpeech.new(Hpricot(good_form8), @page).extract_speakername)
  #  assert_equal(["Opposition members", nil, false], HansardSpeech.new(Hpricot(good_form9), @page).extract_speakername)
  #  
  #  assert_equal([nil, nil, false], HansardSpeech.new(Hpricot(bad_form1), @page).extract_speakername)
  #  assert_equal([nil, nil, false], HansardSpeech.new(Hpricot(bad_form2), @page).extract_speakername)
  #end
  
  #def test_extract_speakername_from_motionnospeech
  #  good_form1 = '<div class="motionnospeech"><span class="speechname">Mr ABBOTT</span></div>'
  #  
  #  assert_equal(["Mr ABBOTT", nil, false], HansardSpeech.new(Hpricot(good_form1), @page).extract_speakername)
  #end
  
  def test_generic_speakers
    speech = HansardSpeech.new(Hpricot(''), @page)
    assert(HansardSpeech.generic_speaker?("Honourable member"))
    assert(HansardSpeech.generic_speaker?("Honourable members"))
    assert(HansardSpeech.generic_speaker?("Government member"))
    assert(HansardSpeech.generic_speaker?("Government members"))
    assert(HansardSpeech.generic_speaker?("Opposition member"))
    assert(HansardSpeech.generic_speaker?("Opposition members"))
    assert(HansardSpeech.generic_speaker?("a government member"))
    
    assert(!HansardSpeech.generic_speaker?("John Smith"))
  end
  
  #def test_remove_generic_speaker_names
  #  assert_equal('<p>Hear, hear!</p>', HansardSpeech.new(Hpricot('<p><b>Honourable members</b>—Hear, hear!</p>'), @page).clean_content.to_s)
  #  assert_equal('<p>Hear, hear!</p>', HansardSpeech.new(Hpricot('<p><b>Government members</b>—Hear, hear!</p>'), @page).clean_content.to_s)
  #  assert_equal('<p>Hear, hear!</p>', HansardSpeech.new(Hpricot('<p><b>Opposition members</b>—Hear, hear!</p>'), @page).clean_content.to_s)
  #  assert_equal('<p>Hear, hear!</p>', HansardSpeech.new(Hpricot('<p><b>A government member</b>—Hear, hear!</p>'), @page).clean_content.to_s)
  #  assert_equal('<p>My <b>Honourable members</b>I beseech thee to not use greedy regexes!</p>', HansardSpeech.new(Hpricot('<p><b>Honourable members</b>—My <b>Honourable members</b>—I beseech thee to not use greedy regexes!</p>'), @page).clean_content.to_s)
  #  assert_equal('<p class="italic">Honourable members interjecting—</p>', HansardSpeech.new(Hpricot('<p class="paraitalic">Honourable members interjecting—</p>'), @page).clean_content.to_s)
  #  assert_equal('<p>Hear, hear!</p>', HansardSpeech.new(Hpricot('<p class="block"><b>Opposition members</b>—Hear, hear!</p>'), @page).clean_content.to_s)
  #end 
end
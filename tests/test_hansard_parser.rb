#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'test/unit'
require 'hansard_parser'
require 'rubygems'
require 'hpricot'
require 'people'

class TestHansardParser < Test::Unit::TestCase
  def setup
    @page = HansardPage.new(nil, nil, nil)
  end
  
  def test_make_motions_and_quotes_italic
    doc = Hpricot('<p>I move:</p><div class="motion"><p>Some text</p></div>')
    @page.make_motions_and_quotes_italic(doc)
    assert_equal('<p>I move:</p><p class="italic">Some text</p>', doc.to_s)
  end
  
  def test_remove_subspeech_tags
    doc = Hpricot('<div class="subspeech0"><p>Some Text</p></div><div class="subspeech0"><p>Some Other Text</p></div>')
    @page.remove_subspeech_tags(doc)
    assert_equal('<p>Some Text</p><p>Some Other Text</p>', doc.to_s)
  end

  def test_fix_links_relative_link
    doc = Hpricot('<p>The <a href="foo.html">Link Text</a> Some Text</p>')
    @page.fix_links("http://website/bar/blah.html", doc)
    assert_equal('<p>The <a href="http://website/bar/foo.html">Link Text</a> Some Text</p>', doc.to_s)
  end
  
  def test_fix_links_absolute_link
    doc = Hpricot('<p>The <a href="http://anothersite/foo.html">Link Text</a> Some Text</p>')
    @page.fix_links("http://website/bar/blah.html", doc)
    assert_equal('<p>The <a href="http://anothersite/foo.html">Link Text</a> Some Text</p>', doc.to_s)
  end
  
  def test_fix_links_on_image
    doc = Hpricot('<p>The <img src="/parlinfo/Repository/Chamber/HANSARDR/5320M_image002.jpg" /> Some Text</p>')
    @page.fix_links("http://website/bar/blah.html", doc)
    assert_equal('<p>The <img src="http://website/parlinfo/Repository/Chamber/HANSARDR/5320M_image002.jpg" /> Some Text</p>', doc.to_s)
  end
  
  def test_fix_links_empty_a_tag
    doc = Hpricot('<p>The <a>Link Text</a> Some Text</p>')
    @page.fix_links("http://website/bar/blah.html", doc)
    assert_equal('<p>The Link Text Some Text</p>', doc.to_s)
  end
  
  def test_make_amendments_italic
    doc = Hpricot('<div class="amendments"><div class="amendment0"><p class="paraParlAmend">Some Text</p></div><div class="amendment1"><p class="paraParlAmend">Some more text</p></div></div>')
    @page.make_amendments_italic(doc)
    assert_equal('<p class="italic">Some Text</p><p class="italic">Some more text</p>', doc.to_s)
  end
  
  def test_fix_attributes_of_p_tags_block
    doc = Hpricot('<p class="block">Some Text</p>')
    @page.fix_attributes_of_p_tags(doc)
    assert_equal('<p>Some Text</p>', doc.to_s)
  end
  
  def test_fix_attributes_of_p_tags_parablock
    doc = Hpricot('<p class="parablock">Some Text</p>')
    @page.fix_attributes_of_p_tags(doc)
    assert_equal('<p>Some Text</p>', doc.to_s)
  end

  def test_fix_attributes_of_p_tags_paraitalic
    doc = Hpricot('<p class="paraitalic">Some Text</p>')
    @page.fix_attributes_of_p_tags(doc)
    assert_equal('<p class="italic">Some Text</p>', doc.to_s)
  end
  
  def test_fix_attributes_of_p_tags_parasmalltablejustified
    doc = Hpricot('<p class="parasmalltablejustified">Some Text</p>')
    @page.fix_attributes_of_p_tags(doc)
    assert_equal('<p>Some Text</p>', doc.to_s)
  end
  
  def test_fix_attributes_of_p_tags_text_indent
    doc = Hpricot('<p class="italic" style="text-indent: 0;">Some Text</p>')
    @page.fix_attributes_of_p_tags(doc)
    assert_equal('<p class="italic">Some Text</p>', doc.to_s)
  end
  
  def test_fix_attributes_of_p_tags_parasmalltableleft
    doc = Hpricot('<p class="parasmalltableleft">Some Text</p>')
    @page.fix_attributes_of_p_tags(doc)
    assert_equal('<p>Some Text</p>', doc.to_s)
  end
  
  def test_fix_attributes_of_p_tags_paraheading
    doc = Hpricot('<p class="paraheading">Some Text</p>')
    @page.fix_attributes_of_p_tags(doc)
    assert_equal('<p>Some Text</p>', doc.to_s)
  end
  
  def test_fix_attributes_of_td_tags_style
    doc = Hpricot('<td style="foo">Some Text</td>')
    @page.fix_attributes_of_td_tags(doc)
    assert_equal('<td>Some Text</td>', doc.to_s)
  end
  
  def test_fix_attributes_of_p_tags_parabold
    doc = Hpricot('<p class="parabold">Some Text</p>')
    @page.fix_attributes_of_p_tags(doc)
    assert_equal('<b><p>Some Text</p></b>', doc.to_s)
  end
  
  def test_fix_motionnospeech_tags
    doc = Hpricot(
'<div class="motionnospeech"><span class="speechname">Mr ABBOTT</span><span class="speechelectorate">(Warringah</span><span class="speechrole">Leader of the House)</span><span class="speechtime"></span>Some Text</div>')
    @page.fix_motionnospeech_tags(doc)
    assert_equal('<p>Some Text</p>', doc.to_s)
  end
  
  def test_extract_speakername
    good_form1 = '<p><span class="talkername"><a HREF="blah">Mr Hunt</a></span></p>'
    good_form2 = '<p><span class="talkername"><a>The Deputy Speaker</a></span><b>(Mr Hunt)</p>'
    good_form3 = '<div class="subspeech1"><div class="speechType">Interjection</div><p> <i>Mr Smith interjecting</i>—</p></div>'
    good_form4 = '<div class="subspeech1"><div class="speechType">Interjection</div><p> <i>Ms Johnson</i>—</p></div>'
    good_form5 = '<div class="subspeech1"><div class="speechType">Continue</div><p><span class="talkername"><a href="blah">Mr BAIRD</a></span>—Some words</p></div>'
    good_form6 = '<p><b>Honourable members</b>—Hear, hear!</p>'
    good_form7 = '<p><b>Honourable members</b>—My <b>Honourable members</b>—I beseech thee to not use greedy regexes!</p>'
    good_form8 = '<p class="paraitalic">Honourable members interjecting—</p>'
    good_form9 = '<p class="block"><b>Opposition members</b>—Hear, hear!</p>'
		
		bad_form1 = '<p class="block">Some words.</p>'
		bad_form2 = '<p>Mr Hunt</p>'
		
    assert_equal(["Mr Hunt", "blah", false], @page.extract_speakername(Hpricot(good_form1), House.representatives))
    assert_equal(["The Deputy Speaker (Mr Hunt)", nil, false], @page.extract_speakername(Hpricot(good_form2), House.representatives))
    assert_equal(["Mr Smith", nil, true], @page.extract_speakername(Hpricot(good_form3), House.representatives))
    assert_equal(["Ms Johnson", nil, true], @page.extract_speakername(Hpricot(good_form4), House.representatives))
    assert_equal(["Mr BAIRD", "blah", false], @page.extract_speakername(Hpricot(good_form5), House.representatives))
    assert_equal(["Honourable members", nil, false], @page.extract_speakername(Hpricot(good_form6), House.representatives))
    assert_equal(["Honourable members", nil, false], @page.extract_speakername(Hpricot(good_form7), House.representatives))
    assert_equal(["Honourable members", nil, true], @page.extract_speakername(Hpricot(good_form8), House.representatives))
    assert_equal(["Opposition members", nil, false], @page.extract_speakername(Hpricot(good_form9), House.representatives))
    
    assert_equal([nil, nil, false], @page.extract_speakername(Hpricot(bad_form1), House.representatives))
    assert_equal([nil, nil, false], @page.extract_speakername(Hpricot(bad_form2), House.representatives))
  end
  
  def test_extract_speakername_from_motionnospeech
    good_form1 = '<div class="motionnospeech"><span class="speechname">Mr ABBOTT</span></div>'
    
    assert_equal(["Mr ABBOTT", nil, false], @page.extract_speakername(Hpricot(good_form1), House.representatives))
  end
  
  def test_generic_speakers
    assert(HansardPage.new(nil, nil, nil).generic_speaker?("Honourable member", House.representatives))
    assert(HansardPage.new(nil, nil, nil).generic_speaker?("Honourable members", House.representatives))
    assert(HansardPage.new(nil, nil, nil).generic_speaker?("Government member", House.representatives))
    assert(@page.generic_speaker?("Government members", House.representatives))
    assert(@page.generic_speaker?("Opposition member", House.representatives))
    assert(@page.generic_speaker?("Opposition members", House.representatives))
    assert(@page.generic_speaker?("a government member", House.representatives))
    
    assert(!@page.generic_speaker?("John Smith", House.representatives))
    
    assert_equal('<p>Hear, hear!</p>', @page.remove_generic_speaker_names(Hpricot('<p><b>Honourable members</b>—Hear, hear!</p>'), House.representatives).to_s)
    assert_equal('<p>Hear, hear!</p>', @page.remove_generic_speaker_names(Hpricot('<p><b>Government members</b>—Hear, hear!</p>'), House.representatives).to_s)
    assert_equal('<p>Hear, hear!</p>', @page.remove_generic_speaker_names(Hpricot('<p><b>Opposition members</b>—Hear, hear!</p>'), House.representatives).to_s)
    assert_equal('<p>Hear, hear!</p>', @page.remove_generic_speaker_names(Hpricot('<p><b>A government member</b>—Hear, hear!</p>'), House.representatives).to_s)
    assert_equal('<p>My <b>Honourable members</b>—I beseech thee to not use greedy regexes!</p>', @page.remove_generic_speaker_names(Hpricot('<p><b>Honourable members</b>—My <b>Honourable members</b>—I beseech thee to not use greedy regexes!</p>'), House.representatives).to_s)
    assert_equal('<p class="paraitalic">Honourable members interjecting—</p>', @page.remove_generic_speaker_names(Hpricot('<p class="paraitalic">Honourable members interjecting—</p>'), House.representatives).to_s)
    assert_equal('<p>Hear, hear!</p>', @page.remove_generic_speaker_names(Hpricot('<p class="block"><b>Opposition members</b>—Hear, hear!</p>'), House.representatives).to_s)
  end 
end
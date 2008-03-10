$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'test/unit'
require 'hansard_parser'
require 'rubygems'
require 'hpricot'

class TestHansardParser < Test::Unit::TestCase
  def test_make_motions_and_quotes_italic
    doc = Hpricot('<p>I move:</p><div class="motion"><p>Some text</p></div>')
    HansardParser.make_motions_and_quotes_italic(doc)
    assert_equal('<p>I move:</p><p class="italic">Some text</p>', doc.to_s)
  end
  
  def test_remove_subspeech_tags
    doc = Hpricot('<div class="subspeech0"><p>Some Text</p></div><div class="subspeech0"><p>Some Other Text</p></div>')
    HansardParser.remove_subspeech_tags(doc)
    assert_equal('<p>Some Text</p><p>Some Other Text</p>', doc.to_s)
  end
end
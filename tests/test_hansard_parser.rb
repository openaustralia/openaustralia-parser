$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'test/unit'
require 'hansard_parser'
require 'rubygems'
require 'hpricot'

class TestHansardParser < Test::Unit::TestCase
  def test_make_motions_italic
    doc = Hpricot('<p>I move:</p><div class="motion"><p>Some text</p></div>')
    HansardParser.make_motions_italic(doc)
    assert_equal('<p>I move:</p><p class="italic">Some text</p>', doc.to_s)
  end
end
$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'test/unit'
require 'hansard_parser'
require 'rubygems'
require 'hpricot'

class TestHansardParser < Test::Unit::TestCase
  def test_make_motions_indented
    doc = Hpricot('<p>I move:</p><div class="motion"><p>Some text</p></div>')
    assert_equal('<p>I move:</p><p class="indent">Some text</p>', HansardParser.make_motions_indented(doc).to_s)
  end
end
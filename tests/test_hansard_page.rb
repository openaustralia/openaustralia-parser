$:.unshift "#{File.dirname(__FILE__)}/../lib"

require "test/unit"

require "hansard_page"
require 'rubygems'
require 'hpricot'

class TestHansardPage < Test::Unit::TestCase
  def setup
    @speaker = HansardPage.new(Hpricot.XML('
    <debate>
			<speech></speech>
			<motionnospeech></motionnospeech>
			<interjection></interjection>
			<speech></speech>
			<motionnospeech></motionnospeech>
		</debate>').at('debate'), nil, nil, nil)
  end
  
  def test_speaker
    assert_equal(5, @speaker.speeches.size)
  end  
end
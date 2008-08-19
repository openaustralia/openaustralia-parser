#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'test/unit'
require 'name'
require 'person'
require 'period'
require 'speech'
require 'date'
require 'builder_alpha_attributes'
require 'activesupport'
require 'htmlentities'

$KCODE = 'u'

class TestSpeech < Test::Unit::TestCase
  def setup
    person = Person.new(:name => Name.new(:first => "John", :last => "Smith"), :count => 1)
    member = Period.new(:person => person, :house => House.representatives, :count => 1)
    # TODO: Fix duplication of house both in speaker and initialiser for Speech
    @speech = Speech.new(member, "05:00:00", "http://foo.co.uk/", 3, 1, Date.new(2006, 1, 1), House.representatives)
  end
  
  def test_simple
    @speech.append_to_content(Hpricot('<p>A speech</p>'))
    
    assert_equal(
      '<speech id="uk.org.publicwhip/debate/2006-01-01.3.1" speakerid="uk.org.publicwhip/member/1" speakername="John Smith" time="05:00:00" url="http://foo.co.uk/"><p>A speech</p></speech>',
      @speech.output(Builder::XmlMarkup.new))
  end
  
  def test_html_entity_encoding
    # I'm pretty sure that Mechanize unescapes when it reads things in. So, we'll simulate that here
    nbsp = [160].pack('U')
    doc = Hpricot("<p>Q&A#{nbsp}—</p>")
    # Make sure that you normalise the unicode before comparing.
    assert_equal("<p>Q&A#{nbsp}—</p>".chars.normalize, doc.to_s.chars.normalize)
    
    coder = HTMLEntities.new
    assert_equal("Q&amp;A&nbsp;&mdash;", coder.encode("Q&A#{nbsp}—", :named))
    
    @speech.append_to_content(doc)
    assert_equal(
      '<speech id="uk.org.publicwhip/debate/2006-01-01.3.1" speakerid="uk.org.publicwhip/member/1" speakername="John Smith" time="05:00:00" url="http://foo.co.uk/"><p>Q&amp;A&nbsp;&mdash;</p></speech>',
      @speech.output(Builder::XmlMarkup.new))    
  end
end
$:.unshift "#{File.dirname(__FILE__)}/../lib"

require "test/unit"

require 'speech'
require 'person'
require 'name'
require 'count'
require 'builder_alpha_attributes'

describe Speech do
  before :each do
    person = Person.new(:name => Name.new(:first => "John", :last => "Smith"), :count => 1)
    member = Period.new(:person => person, :house => House.representatives, :count => 1)
    # TODO: Fix duplication of house both in speaker and initialiser for Speech
    @speech = Speech.new(member, "05:00:00", "http://foo.co.uk/", Count.new(3, 1), Date.new(2006, 1, 1), House.representatives)
  end

  it "outputs a simple speech" do
    @speech.append_to_content(Hpricot('<p>A speech</p>'))    
    @speech.output(Builder::XmlMarkup.new).should == '<speech id="uk.org.publicwhip/debate/2006-01-01.3.1" speakerid="uk.org.publicwhip/member/1" speakername="John Smith" talktype="speech" time="05:00:00" url="http://foo.co.uk/"><p>A speech</p></speech>'
  end
  
  it "encodes html entities" do
    # I'm pretty sure that Mechanize unescapes when it reads things in. So, we'll simulate that here
    nbsp = [160].pack('U')
    doc = Hpricot("<p>Q&A#{nbsp}—</p>")
    # Make sure that you normalise the unicode before comparing.
    doc.to_s.mb_chars.normalize.should == "<p>Q&A#{nbsp}—</p>".mb_chars.normalize
    
    coder = HTMLEntities.new
    coder.encode("Q&A#{nbsp}—", :basic).should == "Q&amp;A#{nbsp}—"
    
    @speech.append_to_content(doc)
    @speech.output(Builder::XmlMarkup.new).should == '<speech id="uk.org.publicwhip/debate/2006-01-01.3.1" speakerid="uk.org.publicwhip/member/1" speakername="John Smith" talktype="speech" time="05:00:00" url="http://foo.co.uk/"><p>Q&amp;A' + nbsp + '—</p></speech>'
  end  
end

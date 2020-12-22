# encoding: utf-8

$:.unshift "#{File.dirname(__FILE__)}/../lib"

require "test/unit"

require 'speech'
require 'person'
require 'name'
require 'count'
require 'builder_alpha_attributes'

describe Speech do

  let!(:person){ Person.new(:name => Name.new(:first => "John", :last => "Smith"), :count => 1) }
  let!(:member){ Period.new(:person => person, :house => House.representatives, :count => 1) }

  before :each do
    # TODO: Fix duplication of house both in speaker and initialiser for Speech
    @speech = Speech.new(member, "05:00:00", "http://foo.co.uk/", Count.new(3, 1), Date.new(2006, 1, 1), House.representatives)
  end

  it "outputs a simple speech" do
    @speech.append_to_content(Hpricot('<p>A speech</p>'))
    @speech.output(Builder::XmlMarkup.new).should == '<speech approximate_duration="0" approximate_wordcount="2" id="uk.org.publicwhip/debate/2006-01-01.3.1" speakerid="uk.org.publicwhip/member/1" speakername="John Smith" talktype="speech" time="05:00:00" url="http://foo.co.uk/"><p>A speech</p></speech>'
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
    @speech.output(Builder::XmlMarkup.new).should == '<speech approximate_duration="0" approximate_wordcount="1" id="uk.org.publicwhip/debate/2006-01-01.3.1" speakerid="uk.org.publicwhip/member/1" speakername="John Smith" talktype="speech" time="05:00:00" url="http://foo.co.uk/"><p>Q&amp;A' + nbsp + '—</p></speech>'
  end

  describe "#adjournment" do

    describe "with content with no adjournment" do

      subject{ Speech.new(member, "05:00:00", "<p> some content</p>", Count.new(3, 1), Date.new(2006, 1, 1), House.representatives) }

      it { subject.adjournment.should be_nil }
    end

    describe "with content with an adjournment" do

      let!(:content){ Hpricot("<p> some content\n\nadjourned at 19:31</p>") }
      subject{ Speech.new(member, "09:00:00", 'url', Count.new(3, 1), Date.new(2006, 1, 1), House.representatives) }
      before do
        subject.append_to_content(content)
      end

      it { subject.adjournment.should be_eql(Time.local(2006, 1, 1, 19, 31)) }
    end
  end

  describe "#duration=" do

    describe "with a duration less than zero"  do

      subject{ Speech.new(member, "09:00:00", 'url', Count.new(3, 1), Date.new(2006, 1, 1), House.representatives) }
      before{ subject.duration = -1000 }
      it { subject.duration.should be_zero }
    end

    describe "with a duration that is more than 10 minutes out from an estimate of " +
             "duration made by taking the word count / 120 (average words per minute people speak at) * 60"  do

      subject{ Speech.new(member, "09:00:00", 'url', Count.new(3, 1), Date.new(2006, 1, 1), House.representatives) }
      let!(:minutes_by_wordcount){ 12 }
      let!(:html){ (120 * minutes_by_wordcount).times.map{ "<i>word</i>" }.join(" ") }
      before do
        subject.append_to_content(Hpricot(html))
        subject.duration = 60
      end
      it { subject.duration.should == minutes_by_wordcount * 60 }
    end
  end


  describe "#words" do

    let!(:content){ Hpricot("<p> some content\n\n<span>another word. New sentence.</span> </p>") }
    subject{ Speech.new(member, "09:00:00", 'url', Count.new(3, 1), Date.new(2006, 1, 1), House.representatives) }
    before do
      subject.append_to_content(content)
    end

    it "should return a word count excluding html tags" do
      subject.words.should == 6
    end

    describe "with paragraph tags" do

      let!(:content){ Hpricot("<p>para1</p><p>para2</p>") }

      it "should count the last word of a paragraph and the first word of a new paragraph as two words" do
        subject.words.should == 2
      end
    end
  end
end

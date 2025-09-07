# frozen_string_literal: true

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../lib"

require "test/unit"

require "speech"
require "person"
require "name"
require "count"
require "builder_alpha_attributes"
require "date"


describe Speech do
  let!(:person) { Person.new(name: Name.new(first: "John", last: "Smith"), count: 1) }
  let!(:member) { Period.new(person: person, house: House.representatives, count: 1) }

  before :each do
    # TODO: Fix duplication of house both in speaker and initialiser for Speech
    @speech = Speech.new(speaker: member, time: "05:00:00", url: "http://foo.co.uk/", count: Count.new(3, 1),
                         date: Date.new(2006, 1, 1), house: House.representatives)
  end

  it "outputs a simple speech" do
    @speech.append_to_content(Nokogiri("<p>A speech</p>"))
    expect(@speech.output(Builder::XmlMarkup.new)).to eq '<speech approximate_duration="0" approximate_wordcount="2" id="uk.org.publicwhip/debate/2006-01-01.3.1" speakerid="uk.org.publicwhip/member/1" speakername="John Smith" talktype="speech" time="05:00:00" url="http://foo.co.uk/"><p>A speech</p></speech>'
  end

  it "encodes html entities" do
    # I'm pretty sure that Mechanize unescapes when it reads things in. So, we'll simulate that here
    nbsp = [160].pack("U")
    doc = Nokogiri("<p>Q&A#{nbsp}—</p>")
    # Make sure that you normalise the unicode before comparing.
    expect(doc.to_s.unicode_normalize(:nfkc)).to eq "<p>Q&A#{nbsp}—</p>".unicode_normalize(:nfkc)

    coder = HTMLEntities.new
    expect(coder.encode("Q&A#{nbsp}—", :basic)).to eq "Q&amp;A#{nbsp}—"

    @speech.append_to_content(doc)
    expect(@speech.output(Builder::XmlMarkup.new)).to eq "<speech approximate_duration=\"0\" approximate_wordcount=\"1\" id=\"uk.org.publicwhip/debate/2006-01-01.3.1\" speakerid=\"uk.org.publicwhip/member/1\" speakername=\"John Smith\" talktype=\"speech\" time=\"05:00:00\" url=\"http://foo.co.uk/\"><p>Q&amp;A#{nbsp}—</p></speech>"
  end

  describe "#adjournment" do
    describe "with content with no adjournment" do
      subject do
        Speech.new(speaker: member, time: "05:00:00", url: "<p> some content</p>", count: Count.new(3, 1),
                   date: Date.new(2006, 1, 1), house: House.representatives)
      end

      it { expect(subject.adjournment).to be_nil }
    end

    describe "with content with an adjournment" do
      let!(:content) { Nokogiri("<p> some content\n\nadjourned at 19:31</p>") }
      subject do
        Speech.new(speaker: member, time: "09:00:00", url: "url", count: Count.new(3, 1), date: Date.new(2006, 1, 1),
                   house: House.representatives)
      end
      before do
        subject.append_to_content(content)
      end

      it { expect(subject.adjournment).to be_eql(Time.local(2006, 1, 1, 19, 31)) }
    end
  end

  describe "#duration=" do
    describe "with a duration less than zero" do
      subject do
        Speech.new(speaker: member, time: "09:00:00", url: "url", count: Count.new(3, 1), date: Date.new(2006, 1, 1),
                   house: House.representatives)
      end
      before { subject.duration = -1000 }
      it { expect(subject.duration).to be_zero }
    end

    describe "with a duration that is more than 10 minutes out from an estimate of " \
             "duration made by taking the word count / 120 (average words per minute people speak at) * 60" do
      subject do
        Speech.new(speaker: member, time: "09:00:00", url: "url", count: Count.new(3, 1), date: Date.new(2006, 1, 1),
                   house: House.representatives)
      end
      let!(:minutes_by_wordcount) { 12 }
      let!(:html) { (120 * minutes_by_wordcount).times.map { "<i>word</i>" }.join(" ") }
      before do
        subject.append_to_content(Nokogiri(html))
        subject.duration = 60
      end
      it { expect(subject.duration).to eq minutes_by_wordcount * 60 }
    end
  end

  describe "#words" do
    let!(:content) { Nokogiri("<p> some content\n\n<span>another word. New sentence.</span> </p>") }
    subject do
      Speech.new(speaker: member, time: "09:00:00", url: "url", count: Count.new(3, 1), date: Date.new(2006, 1, 1),
                 house: House.representatives)
    end
    before do
      subject.append_to_content(content)
    end

    it "should return a word count excluding html tags" do
      expect(subject.words).to eq 6
    end

    describe "with paragraph tags" do
      let!(:content) { Nokogiri("<p>para1</p><p>para2</p>") }

      it "should count the last word of a paragraph and the first word of a new paragraph as two words" do
        expect(subject.words).to eq 2
      end
    end
  end
end

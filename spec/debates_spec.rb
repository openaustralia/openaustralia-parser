$:.unshift "#{File.dirname(__FILE__)}/../lib"

require "test/unit"

require "debates"
require 'house'
require 'builder_alpha_attributes'

describe Debates do
  before :each do
    @james = double("Person", :name => double("Name", :full_name => "james"), :id => 101)
    @henry = double("Person", :name => double("Name", :full_name => "henry"), :id => 102)
    @rebecca = double("Person", :name => double("Name", :full_name => "rebecca"), :id => 103)
    @debates = Debates.new(Date.new(2000,1,1), House.representatives)
  end

  it "creates a speech when adding content to an empty debate" do
    @debates.add_speech(@james, "9:00", "url", Hpricot("<p>This is a speech</p>"))

    expect(@debates.output_builder(Builder::XmlMarkup.new(:indent => 2))).to eq <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<debates>
  <speech approximate_duration="0" approximate_wordcount="4" id="uk.org.publicwhip/debate/2000-01-01.1.1" speakerid="101" speakername="james" talktype="speech" time="9:00" url="url">
<p>This is a speech</p>  </speech>
</debates>
EOF
  end

  it "appends to a speech when the speaker is the same" do
    @debates.add_speech(@james, "9:00", "url", Hpricot("<p>This is a speech</p>"))
    @debates.add_speech(@james, "9:00", "url", Hpricot("<p>And a bit more</p>"))

    expect(@debates.output_builder(Builder::XmlMarkup.new(:indent => 2))).to eq <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<debates>
  <speech approximate_duration="0" approximate_wordcount="8" id="uk.org.publicwhip/debate/2000-01-01.1.1" speakerid="101" speakername="james" talktype="speech" time="9:00" url="url">
<p>This is a speech</p><p>And a bit more</p>  </speech>
</debates>
EOF
  end

  it "creates a new speech as an interjection when the speaker changes" do
    @debates.add_speech(@james, "9:00", "url", Hpricot("<p>This is a speech</p>"))
    @debates.increment_minor_count
    @debates.add_speech(@henry, "9:00", "url", Hpricot("<p>And a bit more</p>"), true)

    expect(@debates.output_builder(Builder::XmlMarkup.new(:indent => 2))).to eq <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<debates>
  <speech approximate_duration="0" approximate_wordcount="4" id="uk.org.publicwhip/debate/2000-01-01.1.1" speakerid="101" speakername="james" talktype="speech" time="9:00" url="url">
<p>This is a speech</p>  </speech>
  <speech approximate_duration="0" approximate_wordcount="4" id="uk.org.publicwhip/debate/2000-01-01.1.2" speakerid="102" speakername="henry" talktype="interjection" time="9:00" url="url">
<p>And a bit more</p>  </speech>
</debates>
EOF
  end

  it "appends to a procedural text when the previous speech is procedural" do
    @debates.add_speech(nil, "9:00", "url", Hpricot("<p>This is a speech</p>"))
    @debates.increment_minor_count
    @debates.add_speech(nil, "9:00", "url", Hpricot("<p>And a bit more</p>"))

    expect(@debates.output_builder(Builder::XmlMarkup.new(:indent => 2))).to eq <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<debates>
  <speech approximate_duration="0" approximate_wordcount="8" id="uk.org.publicwhip/debate/2000-01-01.1.1" nospeaker="true" talktype="speech" time="9:00" url="url">
<p>This is a speech</p><p>And a bit more</p>  </speech>
</debates>
EOF
  end

  it "always creates a new speech after a heading" do
    @debates.add_speech(@james, "9:00", "url", Hpricot("<p>This is a speech</p>"))
    @debates.increment_minor_count
    @debates.add_heading("title", "subtitle", "url", [{:id => "Z12345", :title => 'A bill to support mongeese', :url => "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:legislation/billhome/Z12345"}])
    @debates.add_speech(@james, "9:00", "url", Hpricot("<p>And a bit more</p>"))

    expect(@debates.output_builder(Builder::XmlMarkup.new(:indent => 2))).to eq <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<debates>
  <speech approximate_duration="0" approximate_wordcount="4" id="uk.org.publicwhip/debate/2000-01-01.1.1" speakerid="101" speakername="james" talktype="speech" time="9:00" url="url">
<p>This is a speech</p>  </speech>
  <major-heading id="uk.org.publicwhip/debate/2000-01-01.1.2" url="url">
title  </major-heading>
  <minor-heading id="uk.org.publicwhip/debate/2000-01-01.1.3" url="url">
subtitle  </minor-heading>
  <bills>
    <bill id="Z12345" url="http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:legislation/billhome/Z12345">A bill to support mongeese</bill>
  </bills>
  <speech approximate_duration="0" approximate_wordcount="4" id="uk.org.publicwhip/debate/2000-01-01.1.4" speakerid="101" speakername="james" talktype="speech" time="9:00" url="url">
<p>And a bit more</p>  </speech>
</debates>
EOF
  end

  it "creates a new speech for a procedural after a heading" do
    @debates.add_heading("title", "subtitle", "url", [{:id => "Z12345", :title => 'A bill to support mongeese', :url => "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:legislation/billhome/Z12345"}])
    @debates.add_speech(nil, "9:00", "url", Hpricot("<p>This is a speech</p>"))

    expect(@debates.output_builder(Builder::XmlMarkup.new(:indent => 2))).to eq <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<debates>
  <major-heading id="uk.org.publicwhip/debate/2000-01-01.1.1" url="url">
title  </major-heading>
  <minor-heading id="uk.org.publicwhip/debate/2000-01-01.1.2" url="url">
subtitle  </minor-heading>
  <bills>
    <bill id="Z12345" url="http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:legislation/billhome/Z12345">A bill to support mongeese</bill>
  </bills>
  <speech approximate_duration="0" approximate_wordcount="4" id="uk.org.publicwhip/debate/2000-01-01.1.3" nospeaker="true" talktype="speech" time="9:00" url="url">
<p>This is a speech</p>  </speech>
</debates>
EOF
  end

  it "creates a new speech when adding a procedural to a speech by a person" do
    @debates.add_speech(@james, "9:00", "url", Hpricot("<p>This is a speech</p>"))
    @debates.increment_minor_count
    @debates.add_speech(nil, "9:00", "url", Hpricot("<p>And a bit more</p>"))

    expect(@debates.output_builder(Builder::XmlMarkup.new(:indent => 2))).to eq <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<debates>
  <speech approximate_duration="0" approximate_wordcount="4" id="uk.org.publicwhip/debate/2000-01-01.1.1" speakerid="101" speakername="james" talktype="speech" time="9:00" url="url">
<p>This is a speech</p>  </speech>
  <speech approximate_duration="0" approximate_wordcount="4" id="uk.org.publicwhip/debate/2000-01-01.1.2" nospeaker="true" talktype="speech" time="9:00" url="url">
<p>And a bit more</p>  </speech>
</debates>
EOF
  end

  it "creates a new speech as continuation when the original speaker continues" do
    @debates.add_speech(@james, "9:00", "url", Hpricot("<p>This is a speech</p>"))
    @debates.increment_minor_count
    @debates.add_speech(@henry, "9:00", "url", Hpricot("<p>And a bit more</p>"), true)
    @debates.increment_minor_count
    @debates.add_speech(@james, "9:00", "url", Hpricot("<p>And a bit more</p>"), false, true)

    expect(@debates.output_builder(Builder::XmlMarkup.new(:indent => 2))).to eq <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<debates>
  <speech approximate_duration="0" approximate_wordcount="4" id="uk.org.publicwhip/debate/2000-01-01.1.1" speakerid="101" speakername="james" talktype="speech" time="9:00" url="url">
<p>This is a speech</p>  </speech>
  <speech approximate_duration="0" approximate_wordcount="4" id="uk.org.publicwhip/debate/2000-01-01.1.2" speakerid="102" speakername="henry" talktype="interjection" time="9:00" url="url">
<p>And a bit more</p>  </speech>
  <speech approximate_duration="0" approximate_wordcount="4" id="uk.org.publicwhip/debate/2000-01-01.1.3" speakerid="101" speakername="james" talktype="continuation" time="9:00" url="url">
<p>And a bit more</p>  </speech>
</debates>
EOF
  end

  describe "#calculate_speech_durations" do
    before do
      @debates.items.clear
    end

    describe "a speech followed by another speech by a different person" do
      before do
        @debates.add_speech(@james, "9:00", "url", Hpricot("<p>This is a speech</p>"))
        @debates.add_speech(@henry, "9:08", "url", Hpricot("<p>And a bit more</p>"))
        @debates.calculate_speech_durations
      end

      it "should calculate the duration based on the start of the next speech" do
        expect(@debates.items.first.duration).to eq 8 * 60
      end
    end

    describe "a speech followed by an interjection" do
      before do
        @debates.add_speech(@henry, "9:08", "url", Hpricot("<p>And a bit more</p>"))
        @debates.add_speech(@james, "9:12", "url", Hpricot("<p>I interject!</p>"), true)
        @debates.add_speech(@rebecca, "9:18", "url", Hpricot("<p>I interject!</p>"))
        @debates.calculate_speech_durations
      end

      it "should calculate the duration based on the start of the next speech - skipping interjectsions" do
        expect(@debates.items.first.duration).to eq 10 * 60
      end
    end

    describe "the last section with an adjournment time in the data" do
      before do
        @debates.add_speech(@rebecca, "9:18", "url", Hpricot("<p>Some text adjourned at 9:21</p>"))
        @debates.add_speech(@rebecca, "9:50", "url", Hpricot("<p>Post adjournment</p>"))
        @debates.calculate_speech_durations
      end

      it "should use the adjournment time to work out the duration" do
        expect(@debates.items.first.duration).to eq 3 * 60
      end
    end

    describe "an interjection" do
      before do
        @debates.add_speech(@james, "9:00", "url", Hpricot("<p>I interject!</p>"), true)
        @debates.add_speech(@henry, "9:08", "url", Hpricot("<p>And a bit more</p>"))
        @debates.calculate_speech_durations
      end

      it "should not have a duration set" do
        expect(@debates.items.first.duration).to be_zero
      end
    end

    describe "a continuation" do
      before do
        @debates.add_speech(@james, "9:00", "url", Hpricot("<p>I interject!</p>"))
        @debates.add_speech(@henry, "9:04", "url", Hpricot("<p>I interject!</p>"), true)
        @debates.add_speech(@james, "9:08", "url", Hpricot("<p>I interject!</p>"), false, true)
        @debates.add_speech(@henry, "9:12", "url", Hpricot("<p>And a bit more</p>"))
        @debates.calculate_speech_durations
      end

      it "should not have a duration set" do
        expect(@debates.items[2].duration).to be_zero
      end
    end

    describe "a speech without a time (this rarely occurs but somtimes the xml is that broken)" do
      before do
        @html = "<p>This is a speech</p>" * (121 * 3) # over 10 minutes of words
        @debates.add_speech(@james, nil, "url", Hpricot(@html))
        @debates.add_speech(@henry, "9:08", "url", Hpricot("<p>And a bit more</p>"))
        @debates.calculate_speech_durations
      end

      it "should fallback to an estimate based on word count / 120 (the number of words spoken per minute)" do
        expect(@debates.items[0].duration).to eq (121 * 4 * 3 / 120).round * 60
      end
    end

    describe "a speech followed by a continuation" do
      before do
        # Add a speech with only 1 minute of words
        @debates.add_speech(@james, "9:08", "url", Hpricot("test " * 120))
        # Add an interjection
        @debates.add_speech(@henry, "9:08", "url", Hpricot("<p>And a bit more</p>"), true)
        # Add a continuation with 10 minutes of words
        @debates.add_speech(@james, "9:08", "url", Hpricot("test " * (120 * 10)), false, true)
        @debates.calculate_speech_durations
      end

      it "should should use speech.word_count_for_continuations when estimating the duration" do
        expect(@debates.items[0].duration).to eq (11 * 60)
      end
    end
  end
end

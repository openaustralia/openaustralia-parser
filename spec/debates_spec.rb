$:.unshift "#{File.dirname(__FILE__)}/../lib"

require "test/unit"
require 'spec'

require "debates"
require 'house'
require 'builder_alpha_attributes'

describe Debates do
  before :each do
    @james = mock("Person", :name => mock("Name", :full_name => "james"), :id => 101)
    @henry = mock("Person", :name => mock("Name", :full_name => "henry"), :id => 102)
    @debates = Debates.new(Date.new(2000,1,1), House.representatives)
  end
  
  it "creates a speech when adding content to an empty debate" do
    @debates.add_speech(@james, "9:00", "url", Hpricot("<p>This is a speech</p>"))

    @debates.output_builder(Builder::XmlMarkup.new(:indent => 2)).should == <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<debates>
  <speech id="uk.org.publicwhip/debate/2000-01-01.1.1" speakerid="101" speakername="james" time="9:00" url="url">
<p>This is a speech</p>  </speech>
</debates>
EOF
  end
  
  it "appends to a speech when the speaker is the same" do
    @debates.add_speech(@james, "9:00", "url", Hpricot("<p>This is a speech</p>"))
    @debates.add_speech(@james, "9:00", "url", Hpricot("<p>And a bit more</p>"))

    @debates.output_builder(Builder::XmlMarkup.new(:indent => 2)).should == <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<debates>
  <speech id="uk.org.publicwhip/debate/2000-01-01.1.1" speakerid="101" speakername="james" time="9:00" url="url">
<p>This is a speech</p><p>And a bit more</p>  </speech>
</debates>
EOF
  end
  
  it "creates a new speech when the speaker changes" do
    @debates.add_speech(@james, "9:00", "url", Hpricot("<p>This is a speech</p>"))
    @debates.increment_minor_count
    @debates.add_speech(@henry, "9:00", "url", Hpricot("<p>And a bit more</p>"))

    @debates.output_builder(Builder::XmlMarkup.new(:indent => 2)).should == <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<debates>
  <speech id="uk.org.publicwhip/debate/2000-01-01.1.1" speakerid="101" speakername="james" time="9:00" url="url">
<p>This is a speech</p>  </speech>
  <speech id="uk.org.publicwhip/debate/2000-01-01.1.2" speakerid="102" speakername="henry" time="9:00" url="url">
<p>And a bit more</p>  </speech>
</debates>
EOF
  end
  
  it "appends to a procedural text when the previous speech is procedural" do
    @debates.add_speech(nil, "9:00", "url", Hpricot("<p>This is a speech</p>"))
    @debates.increment_minor_count
    @debates.add_speech(nil, "9:00", "url", Hpricot("<p>And a bit more</p>"))

    @debates.output_builder(Builder::XmlMarkup.new(:indent => 2)).should == <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<debates>
  <speech id="uk.org.publicwhip/debate/2000-01-01.1.1" nospeaker="true" time="9:00" url="url">
<p>This is a speech</p><p>And a bit more</p>  </speech>
</debates>
EOF
  end
  
  it "always creates a new speech after a heading" do
    @debates.add_speech(@james, "9:00", "url", Hpricot("<p>This is a speech</p>"))
    @debates.increment_minor_count
    @debates.add_heading("title", "subtitle", "url")
    @debates.add_speech(@james, "9:00", "url", Hpricot("<p>And a bit more</p>"))

    @debates.output_builder(Builder::XmlMarkup.new(:indent => 2)).should == <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<debates>
  <speech id="uk.org.publicwhip/debate/2000-01-01.1.1" speakerid="101" speakername="james" time="9:00" url="url">
<p>This is a speech</p>  </speech>
  <major-heading id="uk.org.publicwhip/debate/2000-01-01.1.2" url="url">
title  </major-heading>
  <minor-heading id="uk.org.publicwhip/debate/2000-01-01.1.3" url="url">
subtitle  </minor-heading>
  <speech id="uk.org.publicwhip/debate/2000-01-01.1.4" speakerid="101" speakername="james" time="9:00" url="url">
<p>And a bit more</p>  </speech>
</debates>
EOF
  end
  
  it "creates a new speech for a procedural after a heading" do
    @debates.add_heading("title", "subtitle", "url")
    @debates.add_speech(nil, "9:00", "url", Hpricot("<p>This is a speech</p>"))

    @debates.output_builder(Builder::XmlMarkup.new(:indent => 2)).should == <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<debates>
  <major-heading id="uk.org.publicwhip/debate/2000-01-01.1.1" url="url">
title  </major-heading>
  <minor-heading id="uk.org.publicwhip/debate/2000-01-01.1.2" url="url">
subtitle  </minor-heading>
  <speech id="uk.org.publicwhip/debate/2000-01-01.1.3" nospeaker="true" time="9:00" url="url">
<p>This is a speech</p>  </speech>
</debates>
EOF
  end
  
  it "creates a new speech when adding a procedural to a speech by a person" do
    @debates.add_speech(@james, "9:00", "url", Hpricot("<p>This is a speech</p>"))
    @debates.increment_minor_count
    @debates.add_speech(nil, "9:00", "url", Hpricot("<p>And a bit more</p>"))

    @debates.output_builder(Builder::XmlMarkup.new(:indent => 2)).should == <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<debates>
  <speech id="uk.org.publicwhip/debate/2000-01-01.1.1" speakerid="101" speakername="james" time="9:00" url="url">
<p>This is a speech</p>  </speech>
  <speech id="uk.org.publicwhip/debate/2000-01-01.1.2" nospeaker="true" time="9:00" url="url">
<p>And a bit more</p>  </speech>
</debates>
EOF
  end
end

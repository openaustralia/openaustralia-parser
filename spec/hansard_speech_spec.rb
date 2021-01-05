$:.unshift "#{File.dirname(__FILE__)}/../lib"

require "test/unit"

require "hansard_speech"

describe HansardSpeech, "should recognise who's talking" do
  it "in a speech block" do
    speech = HansardSpeech.new(Hpricot.XML('
		<speech>
			<talk.start>
				<talker>
					<name role="metadata">Rudd, Kevin, MP</name>
					<name.id>83T</name.id>
					<name role="display">Mr RUDD</name>
				</talker>
			</talk.start>
		</speech>'), "", "", "", "", nil)

    expect(speech.speakername).to eq "Mr RUDD"
    expect(speech.aph_id).to eq "83T"
    expect(speech.interjection).to be false
    expect(speech.continuation).to be false
  end

  it "in a motionnospeech block" do
    speech = HansardSpeech.new(Hpricot.XML("<motionnospeech><name>Mr BILLSON</name></motionnospeech>").at("motionnospeech"), "", "", "", "", nil)
    expect(speech.speakername).to eq "Mr BILLSON"
    expect(speech.aph_id).to be_nil
    expect(speech.interjection).to be false
    expect(speech.continuation).to be false
  end

  it "in an interjection block" do
    speech = HansardSpeech.new(Hpricot.XML('
	  <interjection>
			<talk.start>
				<talker>
					<name.id>10000</name.id>
					<name role="metadata">SPEAKER, The</name>
					<name role="display">The SPEAKER</name>
				</talker>
			</talk.start>
		</interjection>').at("interjection"), "", "", "", "", nil)
    expect(speech.speakername).to eq "The SPEAKER"
    expect(speech.aph_id).to eq "10000"
    expect(speech.interjection).to be true
    expect(speech.continuation).to be false
  end

  it "is not an interjection if the talker is specified but there is interjecting in the text" do
    speech = HansardSpeech.new(Hpricot.XML('
    <continue>
			<talk.start>
				<talker>
					<name.id>EZ5</name.id>
					<name role="metadata">Abbott, Tony, MP</name>
					<name role="display">Mr ABBOTT</name>
				</talker>
				<para>I listened to all the accusations of bad faith without interjecting.</para>
			</talk.start>
		</continue>').at("continue"), "", "", "", "", nil)
    expect(speech.interjection).to be false
    expect(speech.continuation).to be true
  end

  it "should return the version of the speakername with more information" do
    speech = HansardSpeech.new(Hpricot.XML('
    <interjection>
			<talk.start>
				<talker>
					<name role="metadata">Jenkins, Harry (The DEPUTY SPEAKER)</name>
					<name role="display">The DEPUTY SPEAKER</name>
				</talker>
			</talk.start>
		</interjection>').at("interjection"), "", "", "", "", nil)
    expect(speech.speakername).to eq "Jenkins, Harry (The DEPUTY SPEAKER)"
    expect(speech.interjection).to be true
    expect(speech.continuation).to be false
  end

  it "should recognise generic speakers interjecting" do
    speech = HansardSpeech.new(Hpricot.XML('<para class="italic">Honourable members interjecting—</para>'), "", "", "", "", nil)
    expect(speech.speakername).to eq "Honourable members"
  end
end

describe HansardSpeech, "should clean content" do
  it "in a para (block)" do
    content = '<speech><para class="block">Some text</para></speech>'
    expected = "<p>Some text</p>"
    expect(HansardSpeech.clean_content_para(Hpricot.XML(content).at("para"))).to eq expected

    speech = HansardSpeech.new(Hpricot.XML(content).at("para"), "", "", "", "", nil)
    expect(speech.clean_content.to_s).to eq expected
  end

  it "paragraph with italics" do
    content = '<speech><para>A <inline font-size="12pt">B </inline><inline font-style="italic" font-size="12pt">C</inline><inline font-size="12pt"> D</inline>E</para></speech>'
    expected = "<p>A B <i>C</i> DE</p>"
    expect(HansardSpeech.clean_content_para(Hpricot.XML(content).at("para"))).to eq expected
  end

  it "in a motion block" do
    content = '<motion><para><inline font-size="9pt">Some intro</inline></para><list type="loweralpha"><item label="(a)"><para>Point a</para></item><item label="(b)"><para>Point b</para></item></list></motion>'
    expected_result = '<p pwmotiontext="moved">Some intro<dl><dt>(a)</dt><dd>Point a</dd><dt>(b)</dt><dd>Point b</dd></dl></p>'
    expect(HansardSpeech.new(Hpricot.XML(content).at("motion"), "", "", "", "", nil).clean_content.to_s).to eq expected_result
  end

  # Split the following into separate tests
  it "in an inline block" do
    content = '<para><inline font-size="9.5pt">Some text</inline></para>'
    expected = "Some text"
    expect(HansardSpeech.clean_content_inline(Hpricot.XML(content).at("inline"))).to eq expected

    content = '<para><inline font-style="italic">Some text</inline></para>'
    expected = "<i>Some text</i>"
    expect(HansardSpeech.clean_content_inline(Hpricot.XML(content).at("inline"))).to eq expected

    content = '<para><inline font-weight="bold">Some text</inline></para>'
    expected = "<b>Some text</b>"
    expect(HansardSpeech.clean_content_inline(Hpricot.XML(content).at("inline"))).to eq expected
  end

  it "in a list block" do
    content = '<list type="unadorned"><item label=""><para>Some text</para><list type="loweralpha"><item label="(b)"><para>Section b</para></item></list></item></list>'
    expected = "<dl><dt></dt><dd>Some text<dl><dt>(b)</dt><dd>Section b</dd></dl></dd></dl>"
    expect(HansardSpeech.clean_content_list(Hpricot.XML(content).at("list"))).to eq expected
  end

  it "special handling for names in bold in brackets (to handle badly marked up xml)" do
    content = '<speech><para><inline font-weight="bold">(A name)</inline>—Some text</para></speech>'
    expected = "<p>Some text</p>"
    expect(HansardSpeech.clean_content_para(Hpricot.XML(content).at("para"))).to eq expected
  end

  it "special handling for generic names in bold that should be removed (to handle badly marked up xml)" do
    # For a 'generic name' that isn't in brackets
    content = '<speech><para><inline font-weight="bold">Honourable members</inline>Hear, hear!</para></speech>'
    expected = "<p>Hear, hear!</p>"
    expect(HansardSpeech.clean_content_para(Hpricot.XML(content).at("para"))).to eq expected
  end

  it "should not remove normal text in bold" do
    content = '<speech><para><inline font-weight="bold">Some text in bold</inline>Blah blah</para></speech>'
    expected = "<p><b>Some text in bold</b>Blah blah</p>"
    expect(HansardSpeech.clean_content_para(Hpricot.XML(content).at("para"))).to eq expected
  end

  it "in a table block" do
    content_heading = "<thead><row><entry><para>1</para></entry><entry><para>2</para></entry></row></thead>"
    content_row1 = "<row><entry><para>3</para></entry><entry><para>4</para></entry></row>"
    content_row2 = "<row><entry><para>5</para></entry><entry><para>6</para></entry></row>"
    content = "<table><tgroup><colspec/><colspec/>#{content_heading}<tbody>#{content_row1}#{content_row2}</tbody></tgroup></table>"

    # HACK: 'border=0' is in output table tag (For compatibility with output of previous parser)
    expected = '<table border="0"><tr><td valign="top"><p>1</p></td><td valign="top"><p>2</p></td></tr><tr><td valign="top"><p>3</p></td><td valign="top"><p>4</p></td></tr><tr><td valign="top"><p>5</p></td><td valign="top"><p>6</p></td></tr></table>'
    expect(HansardSpeech.clean_content_table(Hpricot.XML(content).at("table"))).to eq expected
  end

  it "paragraph with non-breaking hyphen" do
    # Unicode Character 'Non-breaking hyphen' (U+2011)
    nbhyphen = [0x2011].pack("U")

    content = "<speech><para>Auditor#{nbhyphen}General</para></speech>"
    expected = "<p>Auditor-General</p>"

    expect(HansardSpeech.clean_content_para(Hpricot.XML(content).at("para"))).to eq expected
  end

  # Only remove the first non-breaking-space from paragraph for compatibility with previous parser
  it "paragraph with non-breaking spaces" do
    nbsp = [160].pack("U")
    content = "<speech><para>#{nbsp}#{nbsp}#{nbsp} Foo</para></speech>"
    expected = "<p>#{nbsp}#{nbsp} Foo</p>"
    expect(HansardSpeech.clean_content_para(Hpricot.XML(content).at("para")).unicode_normalize(:nfkc)).to eq expected.unicode_normalize(:nfkc)
  end

  it "in a graphic block" do
    # Okay, this is stupid beyond belief. On Parlinfo Search the images are missing. However, it appears the links to the image
    # that existed on Parlinfo web are still working. So, I'll use those.
    content = '<graphic href="5340M_image002.jpg"/>'
    expected = '<img src="http://parlinfoweb.aph.gov.au/parlinfo/Repository/Chamber/HANSARDR/5340M_image002.jpg"/>'
    expect(HansardSpeech.clean_content_graphic(Hpricot.XML(content).at("graphic"))).to eq expected
  end

  it "inline with link to bill" do
    content = '<para><inline ref="R2715">Some text</inline></para>'
    expected = '<a href="http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:legislation/billhome/R2715">Some text</a>'
    expect(HansardSpeech.clean_content_inline(Hpricot.XML(content).at("inline"))).to eq expected
  end

  it "paragraph with superscript" do
    content = '<para>E = mc<inline font-variant="superscript">2</inline></para>'
    expected = "<p>E = mc<sup>2</sup></p>"
    expect(HansardSpeech.clean_content_para(Hpricot.XML(content).at("para"))).to eq expected
  end

  it "paragraph with subscript" do
    content = '<para>CO<inline font-variant="subscript">2</inline></para>'
    expected = "<p>CO<sub>2</sub></p>"
    expect(HansardSpeech.clean_content_para(Hpricot.XML(content).at("para"))).to eq expected
  end

  it "marks motions so they can be understood by the public whip application" do
    content = "<motion><para>That yellow is very happy colour</para></motion>"
    expected = '<p pwmotiontext="moved">That yellow is very happy colour</p>'
    expect(HansardSpeech.new(Hpricot.XML(content).at("motion"), "", "", "", "", nil).clean_content.to_s).to eq expected
  end

  it "wraps inlines in motionnospeech in <p> tags" do
    content = "<motionnospeech><inline>—I move:</inline><motion><para>That the member be no longer heard.</para></motion><para>Question put.</para></motionnospeech>"
    expected = '<p>I move:</p><p pwmotiontext="moved">That the member be no longer heard.</p><p>Question put.</p>'
    expect(HansardSpeech.new(Hpricot.XML(content).at("motionnospeech"), "", "", "", "", nil).clean_content.to_s).to eq expected
  end
end

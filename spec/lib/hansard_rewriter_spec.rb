# frozen_string_literal: true

require_relative "../spec_helper"
require "hansard_rewriter"
require "log4r"

RSpec.describe HansardRewriter do
  describe "with speeches containing xml like '(10<span class=\"HPS-Time\">:01</span>):' " do
    let!(:bad_xml) { File.open("#{File.dirname(__FILE__)}/../fixtures/bad-dates.xml").read }
    let!(:rewriter) { HansardRewriter.new(Log4r::Logger.new("TestHansardParser")) }
    let!(:rewritten_xml) { rewriter.rewrite_xml(Nokogiri::XML(bad_xml)) }

    it "should correctly rewrite the date to the time.stamp tag" do
      # hpricot can't handle xpaths with periods in them, so just use regex
      expect(rewritten_xml.at("talker").inner_html).to match(%r{<time\.stamp>10:01</time\.stamp>})
    end
  end

  describe "with a time span carrying extra surrounding text" do
    # Real example from backfilling 2024: an HPS-Time span containing
    # " (Canberra) (14:24):" instead of just the time (the member's own electorate
    # happened to be "Canberra", the seat containing Parliament House). Previously
    # #ripped_out_time took the *whole* inner_html once it merely matched /\d+:\d\d/
    # anywhere within it, so this reached xml2db.pl as an invalid SQL time value and
    # silently failed the entire load - see PR #253's comments.
    let(:bad_xml) do
      <<~XML
        <talk.text>
          <body>
            <p class="HPS-Normal">
              <span class="HPS-Normal">
                <a href="E3L" type="MemberSpeech">
                  <span class="HPS-MemberSpeech">Mr SMITH</span>
                </a>
                (<span class="HPS-Time"> (Canberra) (14:24):</span>): This is my speech.
              </span>
            </p>
          </body>
        </talk.text>
      XML
    end
    let!(:rewriter) { HansardRewriter.new(Log4r::Logger.new("TestHansardParser")) }

    it "extracts just the HH:MM time, not the surrounding text" do
      expect(rewriter.process_textnode(bad_xml)).to match(%r{<time\.stamp>14:24</time\.stamp>})
    end
  end

  describe "with anonymous/collective interjections (no <a> link to a specific member)" do
    # "Government members interjecting—...", "Opposition senators interjecting—..." etc
    # have no <a href type="Member..."> link identifying who's speaking - just plain
    # text starting with a generic-speaker marker phrase. Previously this fell through
    # to the paragraph-append logic and got silently glued onto whoever was already
    # speaking instead of becoming its own turn - real, silent content
    # misattribution, not a crash. See PR #253's comments.
    let(:bad_xml) do
      <<~XML
        <talk.text>
          <body>
            <p class="HPS-Normal">
              <span class="HPS-Normal">
                <a href="E3L" type="MemberSpeech">
                  <span class="HPS-MemberSpeech">Mr SMITH</span>
                </a>
                (<span class="HPS-Electorate">Testington</span>) (<span class="HPS-Time">10:00</span>): This is my speech.
              </span>
            </p>
            <p class="HPS-Normal">
              <span class="HPS-Normal">Government members interjecting—Hear, hear!</span>
            </p>
          </body>
        </talk.text>
      XML
    end
    let!(:rewriter) { HansardRewriter.new(Log4r::Logger.new("TestHansardParser")) }
    let!(:result) { rewriter.process_textnode(bad_xml) }

    it "gives the generic speaker their own interjection turn" do
      expect(result).to match(%r{<interjection>\s*<talker>\s*<name role="metadata">Government members</name>})
    end

    it "keeps the full original text, including the marker phrase, in that turn's para" do
      expect(result).to include("Government members interjecting")
    end

    it "doesn't glue the interjection onto the preceding speaker's own para" do
      expect(result).to match(%r{<para>This is my speech\.</para>\s*<interjection>})
    end
  end

  describe "with raw <, > and & characters in speech text" do
    # #restore_tags's callers extract plain text (already fully entity-decoded via
    # #inner_text/#santize) and interpolate it straight into a new XML string
    # ("<para>#{restore_tags(text)}</para>"), so unescaped metacharacters get reparsed
    # as real markup. This crashed HansardSpeech.clean_content_any with "Unexpected
    # tag https:" on a real citation ("<https://www.icj-cij.org/...>", angle-bracket
    # URL citation, correctly escaped in the source) - see PR #253's comments.
    let(:bad_xml) do
      <<~XML
        <talk.text>
          <body>
            <p class="HPS-Normal">
              <span class="HPS-Normal">
                <a href="E3L" type="MemberSpeech">
                  <span class="HPS-MemberSpeech">Mr SMITH</span>
                </a>
                (<span class="HPS-Electorate">Testington</span>) (<span class="HPS-Time">10:00</span>): See &lt;https://example.org&gt; for details, and Smith &amp; Jones report.
              </span>
            </p>
          </body>
        </talk.text>
      XML
    end
    let!(:rewriter) { HansardRewriter.new(Log4r::Logger.new("TestHansardParser")) }
    let!(:result) { rewriter.process_textnode(bad_xml) }

    it "produces well-formed XML" do
      doc = Nokogiri::XML(result, &:strict)
      expect(doc.errors).to be_empty
    end

    it "keeps the citation URL and ampersand as real text, not reparsed markup" do
      expect(result).to include("See &lt;https://example.org&gt; for details, and Smith &amp; Jones report.")
    end
  end

  describe "with speeches containing duplicate times" do
    let!(:bad_xml) { File.open("#{File.dirname(__FILE__)}/../fixtures/duplicate-times.xml").read }
    let!(:rewriter) { HansardRewriter.new(Log4r::Logger.new("TestHansardParser")) }
    let!(:rewritten_xml) { rewriter.rewrite_xml(Nokogiri::XML(bad_xml)) }

    it "should correctly rewrite the date to the time.stamp tag" do
      # hpricot can't handle xpaths with periods in them, so just use regex
      expect(rewritten_xml.at("talker").inner_html).to match(%r{<time\.stamp>14:08</time\.stamp>})
    end
  end

  describe "weird problem seen in production that I don't understand" do
    let(:bad_xml) do
      <<~XML
        <talk.text>
          <body
            background=""
            style=""
            xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
            xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
            xmlns:o="urn:schemas-microsoft-com:office:office"
            xmlns:v="urn:schemas-microsoft-com:vml"
            xmlns:wx="http://schemas.microsoft.com/office/word/2003/auxHint"
            xmlns:aml="http://schemas.microsoft.com/aml/2001/core"
            xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture"
            xmlns:w10="urn:schemas-microsoft-com:office:word"
            xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
            xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
            <p class="HPS-Normal" style="direction:ltr;unicode-bidi:normal;">
              <span class="HPS-Normal">
                <a href="E3L" type="MemberAnswer">
                  <span class="HPS-MemberAnswer">Mr MORRISON</span>
                </a>
                (<span class="HPS-Electorate">Cook</span>—<span class="HPS-MinisterialTitles">Prime Minister</span>) (<span class="HPS-Time">14:08</span>): I'm invited, by the member opposite, on these issues. I can refer him to comments by the member for Hunter, where he said:
              </span>
            </p>
            <p class="HPS-Small" style="direction:ltr;unicode-bidi:normal;&#xA;          text-indent:0pt;&#xA;        ">
              <span class="HPS-Small">… after 14 years of trying, the Labor Party has made not one contribution to the reduction—</span>
            </p>
            <p class="HPS-Normal" style="direction:ltr;unicode-bidi:normal;">
              <span class="HPS-Normal">
                <a href="00APG" type="MemberInterjecting">
                  <span class="HPS-MemberInterjecting">The SPEAKER:</span>
                </a>
                Prime Minister, if you could just pause for a second. Prime Minister, your microphone is off. The Manager of Opposition Business can resume his seat. I'm making a ruling. The question did not refer to anything other than the government's policy. Just
                to be very clear: the capacity to speak about opposition policy simply doesn't exist. The Prime Minister has the call.</span>
            </p>
            <p class="HPS-Normal" style="direction:ltr;unicode-bidi:normal;">
              <span class="HPS-Normal">
                <a href="E3L" type="MemberContinuation">
                  <span class="HPS-MemberContinuation">Mr MORRISON:</span>
                </a>
                Thank you, Mr Speaker; I'm well chastised on that matter.
              </span>
            </p>
            <p class="HPS-Normal" style="direction:ltr;unicode-bidi:normal;">
              <span class="HPS-Normal">
                <a href="00APG" type="MemberInterjecting">
                  <span class="HPS-MemberInterjecting">The SPEAKER:</span>
                </a>
                I haven't even started yet!
              </span>
            </p>
            <p class="HPS-Normal" style="direction:ltr;unicode-bidi:normal;">
              <span class="HPS-Normal">
                <a href="E3L" type="MemberContinuation">
                  <span class="HPS-MemberContinuation">Mr MORRISON:</span>
                </a>
                I'm sure! We as a government have set out our goals and our targets very clearly. We've beaten Kyoto I and Kyoto II and we're going to meet and beat the Paris emissions reduction targets that we took to the last election. We went to the last election
                and we said that we would reduce emissions by 2030 by 26 per cent to 28 per cent. As of right now those emissions are down by more than 20 per cent. Australia has one of the highest—if not the highest—rates of rooftop solar take-up anywhere in the
                world. We are seeing a flow, a waterfall, of investment into lower-emissions technologies and renewable technologies in this country like we've never seen before. These are the results of the policies that the government has been putting in place to
                drive down emissions while at the same time taking down electricity prices and investing in the reliability of our grid as we go forward.
              </span>
            </p>
            <p class="HPS-Normal" style="direction:ltr;unicode-bidi:normal;">
              <span class="HPS-Normal">We on this side of the House understand that it's about getting the balance right. You've got to get the balance of affordability and reliability while getting your emissions reductions down, as we are achieving. The minister
                for energy has led the way here with the reforms to the National Energy Market. He's led the way with the lower-emissions technology road map. He's led the way, with me and the Minister for Foreign Affairs, in securing technology partnerships with
                Germany and many other countries to ensure that we're working together to get the technology that Australia needs so that we can meet our emissions reductions targets and prepare our economy for the global challenges ahead. Our policy's pretty
                straightforward: technology, not taxes, to reduce emissions.
              </span>
            </p>
            <a href="HWG" type="GeneralIInterjecting">
              <p class="HPS-Normal" style="direction:ltr;unicode-bidi:normal;">
                <span class="HPS-Normal">
                  <span class="HPS-GeneralIInterjecting">Mr Dreyfus interjecting</span>—</span>
              </p>
            </a>
            <p class="HPS-Normal" style="direction:ltr;unicode-bidi:normal;">
              <span class="HPS-Normal">
                <a href="00APG" type="MemberContinuation">
                  <span class="HPS-MemberContinuation">The SPEAKER:</span>
                </a>
                The member for Isaacs is warned.</span>
            </p>
            <p class="HPS-Normal" style="direction:ltr;unicode-bidi:normal;">
              <span class="HPS-Normal">
                <a href="E3L" type="MemberContinuation">
                  <span class="HPS-MemberContinuation">Mr MORRISON:</span>
                </a>
                With those opposite, when they got the chance, it was tax, tax, tax. Every time you hear the Leader of the Opposition say he wants to reduce emissions, you know he wants to increase your taxes.</span>
            </p>
          </body>
        </talk.text>
      XML
    end
    let!(:rewriter) { HansardRewriter.new(Log4r::Logger.new("TestHansardParser")) }

    it "shouldn't fail" do
      rewriter.process_textnode(bad_xml)
    end
  end
end

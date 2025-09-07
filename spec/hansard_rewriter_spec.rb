# frozen_string_literal: true

require "hansard_rewriter"
require "log4r"

describe HansardRewriter do
  describe "with speeches containing xml like '(10<span class=\"HPS-Time\">:01</span>):' " do
    let!(:bad_xml) { File.open("#{File.dirname(__FILE__)}/fixtures/bad-dates.xml").read }
    let!(:rewriter) { HansardRewriter.new(Log4r::Logger.new("TestHansardParser")) }
    let!(:rewritten_xml) { rewriter.rewrite_xml(Nokogiri.XML(bad_xml)) }

    it "should correctly rewrite the date to the time.stamp tag" do
      # Nokogiri can't handle xpaths with periods in them, so just use regex
      expect(rewritten_xml.at("talker").inner_html).to match(%r{<time\.stamp>10:01</time\.stamp>})
    end
  end

  describe "with speeches containing duplicate times" do
    let!(:bad_xml) { File.open("#{File.dirname(__FILE__)}/fixtures/duplicate-times.xml").read }
    let!(:rewriter) { HansardRewriter.new(Log4r::Logger.new("TestHansardParser")) }
    let!(:rewritten_xml) { rewriter.rewrite_xml(Nokogiri.XML(bad_xml)) }

    it "should correctly rewrite the date to the time.stamp tag" do
      # Nokogiri can't handle xpaths with periods in them, so just use regex
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

require 'hansard_rewriter'
require 'log4r'

describe HansardRewriter do

  describe "with speeches containing xml like '(10<span class=\"HPS-Time\">:01</span>):' " do

    let!(:bad_xml){ File.open("#{File.dirname(__FILE__)}/fixtures/bad-dates.xml").read }
    let!(:rewriter){ HansardRewriter.new(Log4r::Logger.new('TestHansardParser')) }
    let!(:rewritten_xml){ rewriter.rewrite_xml(Hpricot.XML(bad_xml)) }

    it "should correctly rewrite the date to the time.stamp tag" do
      # hpricot can't handle xpaths with periods in them, so just use regex
      rewritten_xml.at('talker').inner_html.should =~ /<time\.stamp>10:01<\/time\.stamp>/
    end
  end
end

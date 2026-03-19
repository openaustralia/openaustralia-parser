# frozen_string_literal: true

require_relative "../spec_helper"
require "hansard_rewriter"
require "log4r"

RSpec.describe HansardRewriter do
  describe "#rewrite_xml" do
    context "with incorrectly formatted xml time like '(10<span class=\"HPS-Time\">:01</span>):' " do
      let!(:bad_xml) { File.read("#{File.dirname(__FILE__)}/../fixtures/bad-dates.xml") }
      let!(:rewriter) { HansardRewriter.new(Log4r::Logger.new("TestHansardParser")) }
      let!(:rewritten_xml) { rewriter.rewrite_xml(Nokogiri::XML(bad_xml)) }

      it "should correctly rewrite the date to the time.stamp tag" do
        # hpricot can't handle xpaths with periods in them, so just use regex
        talker_node = rewritten_xml.at("talker")
        expect(talker_node).not_to be_nil, "Talker node should exist in rewritten XML"
        expect(talker_node.inner_html).to match(%r{<time\.stamp>10:01</time\.stamp>})
      end
    end

    context "with duplicate times for one of two speakers" do
      let!(:bad_xml) { File.open("#{File.dirname(__FILE__)}/../fixtures/duplicate-times.xml").read }
      let!(:rewriter) { HansardRewriter.new(Log4r::Logger.new("TestHansardParser")) }
      let!(:rewritten_xml) { rewriter.rewrite_xml(Nokogiri::XML(bad_xml)) }

      it "should correctly rewrite the date to the time.stamp tag" do
        talker_nodes = rewritten_xml.search("//talker")
        expect(talker_nodes.length).to eq(2) #, "Two Talker nodes should exist in rewritten XML"
        expect(talker_nodes[0].inner_html).to match(%r{<time\.stamp>14:08</time\.stamp>})
        expect(talker_nodes[1].inner_html).to match(%r{<time\.stamp>14:09</time\.stamp>})
      end
    end
  end

  describe "#process_textnode" do

    context "weird problem seen in production that I don't understand" do
      let(:bad_xml) { File.read("#{File.dirname(__FILE__)}/../fixtures/bad-xml-example.xml") }
      let!(:rewriter) { HansardRewriter.new(Log4r::Logger.new("TestHansardParser")) }

      it "shouldn't fail" do
        rewriter.process_textnode(bad_xml)
      end
    end
  end
end

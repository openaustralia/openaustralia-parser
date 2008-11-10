$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'rubygems'
require "test/unit"
require 'spec'

require "hansard_page"

describe HansardPage do
  it "should split a page into speeches" do
    speaker = HansardPage.new([Hpricot.XML(
			'<speech>
			  <talk.start></talk.start>
			  <interjection></interjection>
			  <para></para>
			</speech>').at('speech')], nil, nil, nil)
    
    speaker.speeches.size.should == 3
  end
end

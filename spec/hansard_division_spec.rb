$:.unshift "#{File.dirname(__FILE__)}/../lib"

require "test/unit"

require "hansard_division"
require 'hpricot'

describe HansardDivision do
  before :each do
    # Tellers are indicated with a "*". There might be or might not be a space before the "*".
    @division = HansardDivision.new(Hpricot.XML('
    <division>
			<division.header>
				<time.stamp>09:06:00</time.stamp>
				<para>The House divided.&#xA0;&#xA0;&#xA0;&#xA0; </para>
			</division.header>
			<para>(The Speaker&#x2014;Mr Harry Jenkins)</para>
			<division.data>
				<ayes>
					<num.votes>3</num.votes>
					<title>AYES</title>
					<names>
						<name>Joe Bloggs *</name>
						<name>Henry Smith</name>
						<name>Phil Smith*</name>
					</names>
				</ayes>
				<noes>
					<num.votes>1</num.votes>
					<title>NOES</title>
					<names>
						<name>John Smith *</name>
					</names>
				</noes>
			</division.data>
			<para>* denotes teller</para>
			<division.result>
				<para>Question agreed to.</para>
			</division.result>
		</division>'), "", "", nil)
  end
  
  it "should parse the xml for a division correctly" do
		# Note that the *'s are stripped from the names
		@division.yes.should == ["Joe Bloggs", "Henry Smith", "Phil Smith"]
		@division.no.should == ["John Smith"]
  end
  
  it "should know the time the division took place" do
		@division.time.should == "09:06:00"
  end

  it "should recognise the tellers" do
    @division.yes_tellers == ["Joe Bloggs", "Phil Smith"]
    @division.no_tellers == ["John Smith"]
  end  
end

describe HansardDivision, "with pairings" do
  before(:each) do
    @division = HansardDivision.new(Hpricot.XML(
      '<division>
          <division.header>
              <time.stamp>10:36:00</time.stamp>
              <para>The Senate divided.&#xA0;&#xA0;&#xA0;&#xA0; </para>
          </division.header>
          <para>(The President&#x2014;Senator the Hon. JJ Hogg)</para>
          <division.data>
              <pairs>
                  <num.votes>2</num.votes>
                  <title>PAIRS</title>
                  <names>
                      <name>Lundy, K.A.</name>
                      <name>McGauran, J.J.J.</name>
                      <name>Stephens, U.</name>
                      <name>Barnett, G.</name>
                  </names>
              </pairs>
          </division.data>
          <para>* denotes teller</para>
          <division.result>
              <para>Question negatived.</para>
          </division.result>
      </division>'), "", "", nil)
  end

  it "should parse the pairs votes" do
    @division.pairs.should == [["Lundy, K.A.", "McGauran, J.J.J."], ["Stephens, U.", "Barnett, G."]]
  end

  describe "with no timestamp but a time in the preamble" do

    let(:division_without_timestamp) do
      HansardDivision.new(Hpricot.XML('
    <division>
			<division.header>
         <body>
           <p class="HPS-DivisionPreamble">The House divided. [09:32]<br />(The Speaker—Ms Anna Burke)</p>
         </body>
			</division.header>
			<para>(The Speaker&#x2014;Mr Harry Jenkins)</para>
			<division.data>
				<ayes>
					<num.votes>3</num.votes>
					<title>AYES</title>
					<names>
						<name>Joe Bloggs *</name>
						<name>Henry Smith</name>
						<name>Phil Smith*</name>
					</names>
				</ayes>
				<noes>
					<num.votes>1</num.votes>
					<title>NOES</title>
					<names>
						<name>John Smith *</name>
					</names>
				</noes>
			</division.data>
			<para>* denotes teller</para>
			<division.result>
				<para>Question agreed to.</para>
			</division.result>
		</division>'), "", "", nil)
    end

    it "should correctly extract the time" do
      division_without_timestamp.time.should == '09:32'
    end
  end
end

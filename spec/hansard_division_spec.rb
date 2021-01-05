$:.unshift "#{File.dirname(__FILE__)}/../lib"

require "test/unit"

require "hansard_division"
require "hansard_day"
require "hpricot"

describe HansardDivision do
  subject(:division) do
    # Tellers are indicated with a "*". There might be or might not be a space before the "*".
    HansardDivision.new(Hpricot.XML('
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
		</division>'), "", "", "", double(HansardDay, add_speaker_to_tied_votes?: true))
  end

  it "should parse the xml for a division correctly" do
    # Note that the *'s are stripped from the names
    expect(division.yes).to eq ["Joe Bloggs", "Henry Smith", "Phil Smith"]
    expect(division.no).to eq ["John Smith"]
  end

  it "should know the time the division took place" do
    expect(division.time).to eq "09:06:00"
  end

  it "should recognise the tellers" do
    expect(division.yes_tellers).to eq ["Joe Bloggs", "Phil Smith"]
    expect(division.no_tellers).to eq ["John Smith"]
  end

  describe "#passed?" do
    it { expect(division.passed?).to be true }
  end

  describe "tied vote" do
    let(:old_tied_division_xml) do
      Hpricot.XML('
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
              <name>Bloggs, Joe*</name>
              <name>Smith, Henry</name>
              <name>Smith, Phil*</name>
            </names>
          </ayes>
          <noes>
            <num.votes>3</num.votes>
            <title>NOES</title>
            <names>
              <name>Smith, John*</name>
              <name>Doe, Jane</name>
              <name>Quitecontrary, Mary</name>
            </names>
          </noes>
        </division.data>
        <para>* denotes teller</para>
        <interjection>
          <talk.start>
            <talker>
              <name.id>10000</name.id>
              <name role="metadata">SPEAKER, The</name>
              <name role="display">The SPEAKER</name>
            </talker>
            <para>—I use my casting vote with the noes on the basis of precedents that indicate leaving propositions in their original state.</para>
          </talk.start>
        </interjection>
        <division.result>
          <para>Question negatived.</para>
        </division.result>
      </division>')
    end
    # There's a slightly different layout in newer XML
    let(:new_tied_division_xml) do
      Hpricot.XML('
      <division>
        <division.header>
          <body>
            <p class="HPS-DivisionPreamble">The House divided. [16:13]<br />(The Speaker—Ms Anna Burke)</p>
          </body>
        </division.header>
        <division.data>
          <ayes>
            <num.votes>3</num.votes>
            <title>AYES</title>
            <names>
              <name>Bloggs, Joe*</name>
              <name>Smith, Henry</name>
              <name>Smith, Phil*</name>
            </names>
          </ayes>
          <noes>
            <num.votes>3</num.votes>
            <title>NOES</title>
            <names>
              <name>Smith, John*</name>
              <name>Doe, Jane</name>
              <name>Quitecontrary, Mary</name>
            </names>
          </noes>
         </division.data>
        <division.result>
          <body>
            <p class="HPS-DivisionFooter">The numbers for the ayes and the noes being equal, the Speaker gave her casting vote with the noes.<br />Question negatived.</p>
          </body>
        </division.result>
      </division>')
    end
    let(:old_tied_division) { HansardDivision.new(old_tied_division_xml, "", "", "", double(HansardDay, add_speaker_to_tied_votes?: true)) }
    let(:new_tied_division) { HansardDivision.new(new_tied_division_xml, "", "", "", double(HansardDay, add_speaker_to_tied_votes?: true)) }

    it "should include the speaker's casting vote in the event of a tie" do
      expect(old_tied_division.no).to eq ["Smith, John", "Doe, Jane", "Quitecontrary, Mary", "Jenkins, Harry"]
      expect(new_tied_division.no).to eq ["Smith, John", "Doe, Jane", "Quitecontrary, Mary", "Burke, Anna"]
    end

    describe "#tied?" do
      it { expect(old_tied_division.tied?).to be true }
      it { expect(new_tied_division.tied?).to be true }
    end

    describe "#passed?" do
      it { expect(old_tied_division.passed?).to be false }
      it { expect(new_tied_division.passed?).to be false }
    end

    describe "#speaker" do
      it { expect(old_tied_division.speaker).to eq("Jenkins, Harry") }
      it { expect(new_tied_division.speaker).to eq("Burke, Anna") }
    end

    it "should not include speaker's vote when told not to by HansardDay (e.g. for Senate divisions)" do
      expect(HansardDivision.new(old_tied_division_xml, "", "", "", double(HansardDay, add_speaker_to_tied_votes?: false)).no).to eq ["Smith, John", "Doe, Jane", "Quitecontrary, Mary"]
      expect(HansardDivision.new(new_tied_division_xml, "", "", "", double(HansardDay, add_speaker_to_tied_votes?: false)).no).to eq ["Smith, John", "Doe, Jane", "Quitecontrary, Mary"]
    end
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
      </division>'
                                    ), "", "", "", nil)
  end

  it "should parse the pairs votes" do
    expect(@division.pairs).to eq [["Lundy, K.A.", "McGauran, J.J.J."], ["Stephens, U.", "Barnett, G."]]
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
		</division>'), "", "", "", nil)
    end

    it "should correctly extract the time" do
      expect(division_without_timestamp.time).to eq "09:32"
    end
  end
end

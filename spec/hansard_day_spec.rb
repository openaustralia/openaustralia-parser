# frozen_string_literal: true

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../lib"

require "test/unit"

require "hansard_day"

# Make it simpler to generate XML with tags with '.' in them. Translate occurences of '_' to '.'
module Builder
  class MyXmlMarkup < XmlMarkup
    def method_missing(sym, *args, &block)
      super(sym.to_s.tr("_", ".").to_sym, *args, &block)
    end
  end
end

describe HansardDay do
  before(:each) do
    x = Builder::MyXmlMarkup.new

    header_xml = x.hansard do
      x.session_header do
        x.date "2008-09-25"
        x.parliament_no 42
        x.session_no 1
        x.period_no 3
        x.chamber "SENATE"
        x.page_no 0
        x.proof 1
      end
    end

    x = Builder::MyXmlMarkup.new

    @titles_xml = Hpricot.XML(x.hansard do
      x.chamber_xscript do
        x.debate do
          x.debateinfo { x.title 1 }
          x.speech
        end
        x.debate do
          x.debateinfo { x.title 2 }
          x.subdebate_1 do
            x.subdebateinfo do
              x.title 3
              x.title 14
            end
            x.speech
          end
        end

        x.debate do
          x.debateinfo { x.title 4 }
          x.subdebate_1 do
            x.subdebateinfo { x.title 5 }
            x.speech
          end
          x.subdebate_1 do
            x.subdebateinfo { x.title 6 }
            x.speech
          end
        end

        x.debate do
          x.debateinfo do
            x.title 7
            x.cognate do
              x.cognateinfo { x.title 13 }
            end
          end
          x.subdebate_1 do
            x.subdebateinfo { x.title 8 }
            x.speech
          end
          x.subdebate_1 do
            x.subdebateinfo { x.title 9 }
            x.speech
          end
        end

        x.debate do
          x.debateinfo { x.title 10 }
          x.subdebate_1 do
            x.subdebateinfo { x.title 11 }
            x.subdebate_2 do
              x.subdebateinfo { x.title 12 }
              x.speech
            end
          end
        end
      end
    end)

    @header = HansardDay.new(Hpricot.XML(header_xml))

    @titles = HansardDay.new(@titles_xml)
  end

  it "should know what house it's in" do
    expect(@header.house).to eq House.senate
  end

  it "should know the date" do
    expect(@header.date).to eq Date.new(2008, 9, 25)
  end

  it "should know the permanent url" do
    # Make permanent url links back to the Parlinfo Search result. For the time being we will always link back to the top level
    # result for that date rather than the individual speeches.
    expect(@header.permanent_url).to eq "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;adv=yes;orderBy=_fragment_number,doc_date-rev;page=0;query=Dataset%3Ahansards,hansards80%20Date%3A25%2F9%2F2008;rec=0;resCount=Default"
  end

  it "should be able to figure out all the titles and subtitles" do
    expect(@titles.title(@titles_xml.at("debate"))).to eq "1"
    expect(@titles.subtitle(@titles_xml.at("debate"))).to eq ""

    expect(@titles.title(@titles_xml.at("(subdebate.1)"))).to eq "2"
    expect(@titles.subtitle(@titles_xml.at("(subdebate.1)"))).to eq "3; 14"

    expect(@titles.title(@titles_xml.search("(subdebate.1)")[1])).to eq "4"
    expect(@titles.subtitle(@titles_xml.search("(subdebate.1)")[1])).to eq "5"

    expect(@titles.title(@titles_xml.search("(subdebate.1)")[2])).to eq "4"
    expect(@titles.subtitle(@titles_xml.search("(subdebate.1)")[2])).to eq "6"

    expect(@titles.title(@titles_xml.search("(subdebate.1)")[3])).to eq "7; 13"
    expect(@titles.subtitle(@titles_xml.search("(subdebate.1)")[3])).to eq "8"

    expect(@titles.title(@titles_xml.search("(subdebate.1)")[4])).to eq "7; 13"
    expect(@titles.subtitle(@titles_xml.search("(subdebate.1)")[4])).to eq "9"

    expect(@titles.title(@titles_xml.at("(subdebate.2)"))).to eq "10"
    expect(@titles.subtitle(@titles_xml.at("(subdebate.2)"))).to eq "11; 12"
  end

  it "should still be able to figure out the title even when there is a title tag within a title tag" do
    x = Builder::MyXmlMarkup.new
    titles_xml = x.hansard do
      x.chamber_xscript do
        x.debate do
          x.debateinfo do
            x.title 1
            x.cognate { x.cognateinfo { x.title 2 } }
            x.cognate { x.cognateinfo { x.title 3 } }
            x.cognate { x.cognateinfo { x.title { x.title 4 } } }
            x.cognate { x.cognateinfo { x.title { x.title 5 } } }
          end
          x.subdebate_1 do
            x.subdebateinfo do
              x.title 6
            end
            x.speech
          end
        end
      end
    end

    xml = Hpricot.XML(titles_xml)

    expect(HansardDay.new(xml).title(xml.at("(subdebate.1)"))).to eq "1; 2; 3; 4; 5"
    expect(HansardDay.new(xml).subtitle(xml.at("(subdebate.1)"))).to eq "6"
  end

  it "should know when the page is considered in proof stage" do
    expect(@header).to be_in_proof
  end
end

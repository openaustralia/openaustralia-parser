$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'test/unit'

require 'hansard_day'

# Make it simpler to generate XML with tags with '.' in them. Translate occurences of '_' to '.'
module Builder
  class MyXmlMarkup < XmlMarkup
    def method_missing(sym, *args, &block)
      super(sym.to_s.tr('_', '.').to_sym, *args, &block)
    end
  end
end

describe HansardDay do
  before(:each) do
    x = Builder::MyXmlMarkup.new

    header_xml = x.hansard {
      x.session_header {
        x.date "2008-09-25"
        x.parliament_no 42
        x.session_no 1
        x.period_no 3
        x.chamber "SENATE"
        x.page_no 0
        x.proof 1
      }
    }
    
    x = Builder::MyXmlMarkup.new

    @titles_xml = Hpricot.XML(x.hansard {
      x.chamber_xscript {
        x.debate {
       		x.debateinfo { x.title 1 }
       		x.speech
        }
        x.debate {
          x.debateinfo { x.title 2}
          x.subdebate_1 {
            x.subdebateinfo { x.title 3; x.title 14 }
         		x.speech
          }
        }

        x.debate {
          x.debateinfo { x.title 4 }
          x.subdebate_1 {
            x.subdebateinfo { x.title 5 }
         		x.speech
          }
          x.subdebate_1 {
            x.subdebateinfo { x.title 6 }
         		x.speech
          }
        }

        x.debate {
          x.debateinfo {
            x.title 7
            x.cognate {
              x.cognateinfo { x.title 13 }
            }
          }
          x.subdebate_1 {
            x.subdebateinfo { x.title 8 }
         		x.speech
          }
          x.subdebate_1 {
            x.subdebateinfo { x.title 9 }
         		x.speech
          }
        }
        
        x.debate {
    			x.debateinfo { x.title 10 }
    			x.subdebate_1 {
    				x.subdebateinfo { x.title 11 }
    				x.subdebate_2 {
    					x.subdebateinfo { x.title 12 }
           		x.speech
    				}
    			}
    		}
      }
    })

    @header = HansardDay.new(Hpricot.XML(header_xml))

    @titles = HansardDay.new(@titles_xml)    
  end

  it "should know what house it's in" do
    @header.house.should == House.senate
  end

  it "should know the date" do
    @header.date.should == Date.new(2008, 9, 25)
  end

  it "should know the permanent url" do
    # Make permanent url links back to the Parlinfo Search result. For the time being we will always link back to the top level
    # result for that date rather than the individual speeches.
    @header.permanent_url.should == "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;adv=yes;orderBy=_fragment_number,doc_date-rev;page=0;query=Dataset%3Ahansards,hansards80%20Date%3A25%2F9%2F2008;rec=0;resCount=Default"
  end
  
  it "should be able to figure out all the titles and subtitles" do
    @titles.title(@titles_xml.at('debate')).should == "1"
    @titles.subtitle(@titles_xml.at('debate')).should == ""
    
    @titles.title(@titles_xml.at('(subdebate.1)')).should == "2"
    @titles.subtitle(@titles_xml.at('(subdebate.1)')).should == "3; 14"
    
    @titles.title(@titles_xml.search('(subdebate.1)')[1]).should == "4"
    @titles.subtitle(@titles_xml.search('(subdebate.1)')[1]).should == "5"
    
    @titles.title(@titles_xml.search('(subdebate.1)')[2]).should == "4"
    @titles.subtitle(@titles_xml.search('(subdebate.1)')[2]).should == "6"
    
    @titles.title(@titles_xml.search('(subdebate.1)')[3]).should == "7; 13"
    @titles.subtitle(@titles_xml.search('(subdebate.1)')[3]).should == "8"
    
    @titles.title(@titles_xml.search('(subdebate.1)')[4]).should == "7; 13"
    @titles.subtitle(@titles_xml.search('(subdebate.1)')[4]).should == "9"

    @titles.title(@titles_xml.at('(subdebate.2)')).should == "10"
    @titles.subtitle(@titles_xml.at('(subdebate.2)')).should == "11; 12"
  end  

  it "should still be able to figure out the title even when there is a title tag within a title tag" do
    x = Builder::MyXmlMarkup.new
    titles_xml = x.hansard {
      x.chamber_xscript {
        x.debate {
          x.debateinfo {
            x.title 1
            x.cognate { x.cognateinfo { x.title 2 } }
            x.cognate { x.cognateinfo { x.title 3 } }
            x.cognate { x.cognateinfo { x.title { x.title 4 } } }
            x.cognate { x.cognateinfo { x.title { x.title 5 } } }
          }
          x.subdebate_1 {
            x.subdebateinfo {
              x.title 6
            }
            x.speech
          }
        }
      }
    }
    
    xml = Hpricot.XML(titles_xml)
    
    HansardDay.new(xml).title(xml.at('(subdebate.1)')).should == "1; 2; 3; 4; 5"
    HansardDay.new(xml).subtitle(xml.at('(subdebate.1)')).should == "6"
  end
  
  it "should know when the page is considered in proof stage" do
    @header.should be_in_proof
  end
end

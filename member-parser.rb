#!/usr/bin/env ruby

require 'rubygems'
require 'hpricot'
require 'id'
require 'name'
require 'member'


class MemberParser
    
    @election_dates = {
        "2007" => "2007-11-24",
        "2004" => "2004-10-07",
        "2001" => "2001-11-10",
        "1998" => "1998-10-03",
        "1996" => "1996-03-02",
        "1993" => "1993-03-13",
        "1990" => "1990-03-24"        
    }
    
    def self.extract_house_section_from_parliamentary_service(text)
      m = text.match(/(elected to the house of representatives.*) elected/i)
      if m.nil?
        m = text.match(/(elected to the house of representatives.*)/i)
      end
      return m[1]
    end
    
    def self.parse_house_service(text)
      if text =~ /by-election/i
          m = text.match(/elected to the house of representatives for.*by-election( on)? ([.0-9]*)/i)
          to_format = m[2]
          d = to_format.match(/([0-9]*).([0-9]*).([0-9]*)/)
          
          year = d[3].to_i
          year += 1900 if year < 1900 
          
          n_date = Date.new(year, d[2].to_i, d[1].to_i)
          from_date = n_date.to_s
          fromwhy = "by_election"
      else
          m = text.match(/elected to the house of representatives for[^0-9]*([0-9]*)/i)
          from_date = @election_dates[m[1]]
          fromwhy = "general_election"
      end
      
      if text =~ /defeated at general elections [0-9]{4}/i
          m = text.match(/re-elected[^0-9]*([0-9]*)/i)
          from_date = @election_dates[m[1]]
          fromwhy = "general_election"
      end
      
      return from_date, fromwhy
    end
    
    def self.parse_parliamentary_service_text(psText)
      houseText = extract_house_section_from_parliamentary_service(psText)
      parse_house_service(houseText)
    end
    
    # parses member information from http://parlinfoweb.aph.gov.au/
    # expects the url of the page and an html dom for hpricot
    # returns a Member
    def self.parse(url, doc)
        name = Name.last_title_first(doc.search("#txtTitle").inner_text.to_s[14..-1])
        constituency = doc.search("#dlMetadata__ctl3_Label3").inner_html
        content = doc.search('div#contentstart')
        party = content.search("p")[1].inner_html
        if party == "Australian Labor Party"
            party = "Labor"
        elsif party == "Liberal Party of Australia"
            party = "Liberal"
        elsif party =~ /^The Nationals/
            party = "The Nationals"
        elsif party =~ /^Independent/
            party = "Independent"
        elsif party == "Country Liberal Party"
        else
            throw "Unknown party: #{party}"
        end

        # Grab image of member
        img_tag = content.search("img").first
        # If image is available
        if img_tag
          relative_image_url = img_tag.attributes['src']
          image_url = url + URI.parse(relative_image_url)
        end

        # Collect up all the text between the <h2>Parliamentary service</h2> and the next <h2> tag
        psText = doc.to_html.match(/<h2>parliamentary service<\/h2>(.*?)<h2>/mi)[1]
        # Need to remove all tags and replace with space
        psText.gsub!(/<\/?[^>]*>/, " ")
        from_date, fromwhy = parse_parliamentary_service_text(psText)
            
        member = Member.new(:id_member => 0, :id_person => 0,
            :house => "commons",
            :name => name,
            :constituency => constituency,
            :party => party,
            :fromdate => from_date,
            :todate => "9999-12-31",
            :fromwhy => fromwhy,
            :towhy => "still_in_office",
            :image_url => image_url)
    end
end

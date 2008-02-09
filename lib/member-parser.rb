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
    
    # Keep a running tab of the next member and person id
    @@id_member = 1
    @@id_person = 10001
    
    def self.extract_house_service_from_parliamentary_service(text)
      m = text.match(/(elected to the house of representatives.*) elected/i)
      if m.nil?
        m = text.match(/(elected to the house of representatives.*)/i)
      end
      m[1] if m
    end
    
    def self.parse_start_from_house_service(text)
      if text =~ /by-election/i
          m = text.match(/elected to the house of representatives for.*by-election( on)? ([.0-9]*)/i)
          to_format = m[2]
          d = to_format.match(/([0-9]*).([0-9]*).([0-9]*)/)
          
          year = d[3].to_i
          year += 1900 if year < 1900 
          
          n_date = Date.new(year, d[2].to_i, d[1].to_i)
          from_date = n_date.to_s
          from_why = "by_election"
      else
          m = text.match(/elected to the house of representatives for[^0-9]*([0-9]*)/i)
          from_date = @election_dates[m[1]]
          from_why = "general_election"
      end

      return from_date, from_why
    end
    
    def self.parse_house_service_former_member(text)
      # We're assuming that the member is continuously in parliament
      # TODO: Handle member losing election and being re-elected

      from_date, from_why = parse_start_from_house_service(text)

      # TODO: This is wrong!
      to_date = "9999-12-31"
      to_why = "still_in_office"
      
      return from_date, from_why, to_date, to_why
    end
    
    def self.parse_house_service_current_member(text)
      # We're assuming that the member is continuously in parliament
      # TODO: Handle member losing election and being re-elected
      
      from_date, from_why = parse_start_from_house_service(text)

      to_date = "9999-12-31"
      to_why = "still_in_office"
      
      return from_date, from_why, to_date, to_why
    end
    
    def self.parse_party(party)
      if party =~ /^Australian Labor Party/
        "Labor"
      elsif party =~ /^Liberal Party of Australia/ || party == "Liberal Party"
        "Liberal"
      elsif party =~ /^The Nationals/ || party == "National Party of Australia"
        "Nationals"
      elsif party =~ /^Independent/
        "Independent"
      elsif party =~ /Country Liberal Party/
        # TODO: Stupid question: is Country Liberal the same as Liberal?
        "Country Liberal"
      elsif party =~ /^Australian Democrats/
        "Democrat"
      elsif party == "Nuclear Disarmament Party"
        "Nuclear Disarmament Party"
      elsif party =~ /^Christian Democratic Party/
        "Christian Democrat"
      elsif party =~ /^The Greens/ || party =~ /^Australian Greens/
        "Green"
      elsif party =~ /^Australian Progressive Alliance/
        "Australian Progressive Alliance"
      elsif party =~ /^Unite Australia Party/
        "Unite Australia Party"
      elsif party =~ /^Pauline Hanson's One Nation/
        "One Nation"
      else
        puts "WARNING: Unknown party: #{party}"
        party
      end
    end
    
    # parses member information from http://parlinfoweb.aph.gov.au/
    # expects the url of the page and an html dom for hpricot
    # returns a Member
    def self.parse_member(url, doc, current_member)
      name = Name.last_title_first(doc.search("#txtTitle").inner_text.to_s[14..-1])
      constituency = doc.search("#dlMetadata__ctl3_Label3").inner_html
      content = doc.search('div#contentstart')
      party = parse_party(content.search("p")[1].inner_html)
      
      # Grab image of member
      img_tag = content.search("img").first
      # If image is available
      if img_tag
        relative_image_url = img_tag.attributes['src']
        image_url = url + URI.parse(relative_image_url)
      end
      
      # Collect up all the text between the <h2>Parliamentary service</h2> and the next <h2> tag
      match = doc.to_html.match(/<h2>parliamentary service<\/h2>(.*?)<h2>/mi)
      # Barry Thomas Cunningham's biography page is all messed up. This should skip it
      # TODO: Handle Barry Thomas Cunningham correctly (with the correct info returned rather than just skipping)
      return nil if match.nil?
      psText = match[1]
      # Need to remove all tags and replace with space
      psText.gsub!(/<\/?[^>]*>/, " ")
      house_service = extract_house_service_from_parliamentary_service(psText)
      # If this person hasn't been a member of the house of representatives then ignore
      return nil if house_service.nil?
      if current_member
        from_date, from_why, to_date, to_why = parse_house_service_current_member(house_service)
      else
        from_date, from_why, to_date, to_why = parse_house_service_former_member(house_service)
      end
      
      member = Member.new(:id_member => @@id_member, :id_person => @@id_person,
        :house => "commons",
        :name => name,
        :constituency => constituency,
        :party => party,
        :fromdate => from_date,
        :todate => to_date,
        :fromwhy => from_why,
        :towhy => to_why,
        :image_url => image_url)
      
      @@id_member = @@id_member + 1
      @@id_person = @@id_person + 1
      
      member
    end
    
    def self.parse_former_member(url, doc)
      parse_member(url, doc, false)
    end

    def self.parse_current_member(url, doc)
      parse_member(url, doc, true)
    end    
end

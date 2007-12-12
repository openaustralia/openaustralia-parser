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
    
    # parses member information from http://parlinfoweb.aph.gov.au/
    # expects a html dom for hpricot
    # returns a Member
    def self.parse(doc)
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

        arr = []
        doc.search("//h2[text()='Parliamentary service']").each do |h2|
            c = h2.next_sibling
            while c.name != "h2"
                arr << c
                c = c.next_sibling
            end
        end
        # Convert text to lowercase for easier matching
        psText = arr.collect{|p| p.inner_text}.join(" ").downcase
        
        if psText =~ /by-election/
            m = psText.match(/elected to the house of representatives for.*by-election ([.0-9]*)/)
            to_format = m[1]
            d = to_format.match(/([0-9]*).([0-9]*).([0-9]*)/)
            
            year = d[3].to_i
            year += 1900 if year < 1900 
            
            n_date = Date.new(year, d[2].to_i, d[1].to_i)
            from_date = n_date.to_s
            fromwhy = "by_election"
        else
            m = psText.match(/elected to the house of representatives for[^0-9]*([0-9]*)/)
            #puts "Match = #{m[1]}"
            from_date = @election_dates[m[1]]
            fromwhy = "general_election"
        end
        
        if psText =~ /defeated at general elections [0-9]{4}/
            m = psText.match(/re-elected[^0-9]*([0-9]*)/)
            #puts "Match = #{m[1]}"
            from_date = @election_dates[m[1]]
            fromwhy = "general_election"
        end
            
        member = Member.new(:id_member => 0, :id_person => 0,
            :house => "commons",
            :name => name,
            :constituency => constituency,
            :party => party,
            :fromdate => from_date,
            :todate => "9999-12-31",
            :fromwhy => fromwhy,
            :towhy => "still_in_office")
    end
end

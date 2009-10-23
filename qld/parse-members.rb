#!/usr/bin/env ruby
#
# Download list of members from QLD Parliament house website

$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'mechanize_proxy'
agent = MechanizeProxy.new

#require 'rubygems'
#require 'mechanize'
#agent = WWW::Mechanize.new
#require 'nokogiri'
#require 'open-uri'

('A'...'Z').each do |letter|
  begin
    page = agent.get("http://www.parliament.qld.gov.au/view/historical/records1860.asp?SubArea=register_#{letter}&SubNav=register_A")
    #page = Nokogiri::HTML(open("http://www.parliament.qld.gov.au/view/historical/records1860.asp?SubArea=register_A")) 
  rescue WWW::Mechanize::ResponseCodeError => e
    puts "WARNING: Could not get member page for letter #{letter}. Skipping."
    next
  end

  page.search(".normal table").first.search("tr")[1..-1].each do |row|
    elements = []
    e = row.search("td")[0]
    # Remove badly formatted td tags that lie within td tags
    removed = e.search('td')
    removed.remove
    elements << e
    name = elements[0].inner_text.strip
    #p name
    elements += removed
    elements += row.search("td")[1..-1]
    party = elements[1].inner_html.gsub("&nbsp;", "").strip
    terms = elements[2].inner_html.gsub("&nbsp;", "")
    date_ranges = terms.split("<br />").map do |term|
      if term =~ /^\s*(\d+\.\d+\.\d+)\s*-\s*(\d+\.\d+\.\d+)?( \(resigned\))?$/
        begin
          from_date = Date.parse($~[1])        
        rescue ArgumentError
          puts "WARNING: #{name} has invalid date in #{$~[1]}"
        end

        begin
          to_date = Date.parse($~[2]) if $~[2]
        rescue ArgumentError
          puts "WARNING: #{name} has invalid date in #{$~[2]}"
        end
      elsif term == ""
        from_date = nil
        to_date = nil
      else
        puts "WARNING: For #{name} ignoring the term '#{term}' because it's not in an expected form"
      end
      [from_date, to_date]
    end
    date_ranges.each do |date_range|
      puts "name: #{name}, party: #{party}, from_date: #{date_range[0]}, to_date: #{date_range[1]}"
    end
  end
end

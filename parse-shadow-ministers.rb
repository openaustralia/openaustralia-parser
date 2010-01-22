#!/usr/bin/env ruby
# Used to be that we generated data/shadow-ministers.csv by hand
# It turned into "just that little bit too much of a headache to maintain" so trying to automate it by
# scraping pages on the parliamentary website

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'mechanize_proxy'
require 'hpricot'
require 'name'

def simplify_whitespace(str)
  str.gsub(/[\n\t\r]/, " ").squeeze(" ").strip
end

agent = MechanizeProxy.new

# Current shadow ministry page
page = agent.get("http://www.aph.gov.au/library/parl/42/Shadow/")

# Main content section - <sarcasm>look how elegant this is when you do use tables for layouts</sarcasm>
content = page.search('table')[1].search('td')[2]
# Loop through all the elements and do our best to interpret each bit
start_date = nil
content.children.each do |c|
  case c.inner_text.strip
  when "", "Current Parliamentary Information", /The \d+(nd|rd|th) Parliament/, "Shadow Ministry", "Outer Shadow Ministry",
    "Shadow Parliamentary Secretaries"
    # Skip this - do nothing
  when /(.*) -/
    start_date = Date.parse($~[1])
  when "Previous Shadow Ministries"
    # The rest are just links off to the other pages. let's ignore these for the time being
    break
  else
    # Get rid of bits of html that get in the way
    ['strong', 'a', 'b'].each do |search|
      c.search(search).each do |s|
        s.swap s.children.join
      end
    end
    # At this point forward we're assuming this is one or more positions followed by a name
    lines = simplify_whitespace(c.inner_html).split('<br />').map {|t| t.strip}
    # If there are not enough lines just ignore
    if lines.size >= 2
      positions = lines[0..-2]
      name = lines[-1]
      name = Name.title_first_last(lines[-1])
      if name.post_title == "MP"
        # Reformat names if they're an MP
        name = Name.new(:first => name.first, :middle => name.middle, :last => name.last)
      elsif name.title =~ /^Senator/
        # Use Senator for everyone even if they're "Senator the Hon."
        name = Name.new(:title => "Senator", :first => name.first, :middle => name.middle, :last => name.last)
        # Handle senators slightly differently
      else
        raise "Unknown type of person"
      end
      name_string = name.full_name
      start_date_string = "#{start_date.day}/#{start_date.month}/#{start_date.year}"
      # This means there's no end date
      end_date_string = ""
      positions.each do |position|
        puts "#{name_string},#{start_date_string},#{end_date_string},\"#{position}\""
      end
    end
  end
end

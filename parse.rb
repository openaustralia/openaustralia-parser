#!/usr/bin/env ruby

require 'open-uri'
require 'rubygems'
require 'scrapi'

def fetch(url)
	file = "cache/" + url.tr('/', '_')
	if File.exist?(file)
		return open(file).read()
	else
		begin
			content = open(url).read()
			open(file, "w").write(content)
			content
		rescue Exception
			puts "Cleaning up partially written file: #{file}"
			File.delete(file)
		end
	end
end

# House Hansard for 20 September 2007
url = "http://parlinfoweb.aph.gov.au/piweb/browse.aspx?path=Chamber%20%3E%20House%20Hansard%20%3E%202007%20%3E%2020%20September%202007"

link_scraper = Scraper.define do
	process "a", :description=>:text, :url=>"@href"
	result :description, :url
end

index_scraper = Scraper.define do
	array :links
	process "table#Table12", :links => link_scraper
	result :links
end

links = index_scraper.scrape(fetch(url))
for link in links do
	# Only going to consider speeches for the time being
	if link.description =~ /^Speech:/
		puts "Processing section: #{link.description}"
		absolute_url = (URI.parse(url) + link.url).to_s
		fetch(absolute_url)
	end
end

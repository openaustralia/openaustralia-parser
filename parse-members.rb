#!/usr/bin/env ruby
#
# Parsing all the data for members of the House of Representatives

require 'rubygems'
require 'mechanize'
require 'builder'
require 'rmagick'
require 'id'
require 'name'
require 'member'
require 'member-parser'

# Load the configuration
configuration = YAML::load( File.open( 'config.yml' ) )
configuration = {} if !configuration

# Links to the biographies of all *current* members
url = "http://parlinfoweb.aph.gov.au/piweb/browse.aspx?path=Parliamentary%20Handbook%20%3E%20Biographies%20%3E%20Current%20Members"

# Required to workaround long viewstates generated by .NET (whatever that means)
# See http://code.whytheluckystiff.net/hpricot/ticket/13
Hpricot.buffer_size = 262144

agent = WWW::Mechanize.new
agent.set_proxy(configuration["proxy"]["host"], configuration["proxy"]["port"]) if configuration.has_key?("proxy")
page = agent.get(url)

id_member = 1
id_person = 10001
members = []

page.links[29..-4].each do |link|
  throw "Should start with 'Biography for '" unless link.to_s =~ /^Biography for /

  sub_page = agent.click(link)

  member = MemberParser.parse(sub_page.uri, sub_page.parser)
  member.id_member = id_member
  member.id_person = id_person

  members << member

  id_member = id_member + 1
  id_person = id_person + 1

  puts "Processed: #{member.name.informal_name}"
end

xml = File.open('pwdata/members/all-members.xml', 'w')
x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
x.instruct!
x.publicwhip do
  members.each{|m| m.output_member(x)}
end
xml.close

xml = File.open('pwdata/members/people.xml', 'w')
x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
x.instruct!
x.publicwhip do
  members.each do |m|
    m.output_person(x)
    m.small_image.write("pwdata/images/mps/#{m.id_person}.jpg") if m.small_image
    m.big_image.write("pwdata/images/mpsL/#{m.id_person}.jpg") if m.big_image
  end  
end
xml.close

# And load up the database
system("/Users/matthewl/twfy/cvs/mysociety/twfy/scripts/xml2db.pl --members --all --force")
system("cp -R pwdata/images/* /Library/WebServer/Documents/mysociety/twfy/www/docs/images")
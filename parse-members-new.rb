$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'csv'
require 'date'
require 'builder'
require 'rubygems'
require 'mechanize'
require 'RMagick'

require 'name'
require 'configuration'

conf = Configuration.new

# Read in csv file of members data

data = CSV.readlines("data/house_members.csv")
# Remove the first two elements
data.shift
data.shift

# Represents a period in the house of representatives
class HousePeriod
  attr_reader :from_date, :to_date, :from_why, :to_why
  attr_reader :division, :party, :name, :id
  
  @@id = 1
  
  def initialize(params)
    @id = @@id
    @@id = @@id + 1
    @from_date =  params[:from_date]
    @to_date =    params[:to_date]
    @from_why =   params[:from_why]
    @to_why =     params[:to_why]
    @division =   params[:division]
    @party =      params[:party]
    @name  =      params[:name]
    throw "Invalid keys" unless (params.keys -
      [:division, :party, :name, :from_date,
      :to_date, :from_why, :to_why]).empty?
  end
  
  def current?
    @to_why == "current_member"
  end
  
  def output(x)
    x.member(:id => "uk.org.publicwhip/member/#{@id}",
      :house => "commons", :title => @name.title, :firstname => @name.first,
      :lastname => @name.last, :constituency => @division, :party => @party,
      :fromdate => @from_date, :todate => @to_date, :fromwhy => @from_why, :towhy => @to_why)
  end
end

class Person
  attr_reader :name, :id
  attr_accessor :image_url
  
  @@id = 10001
  # Sizes of small thumbnail pictures of members
  @@THUMB_WIDTH = 44
  @@THUMB_HEIGHT = 59
  
  def initialize(name)
    @name = name
    @house_periods = []
    @id = @@id
    @@id = @@id + 1
  end
  
  # Adds a single continuous period when this person was in the house of representatives
  # Note that there might be several of these per person
  def add_house_period(params)
    @house_periods << HousePeriod.new(params.merge(:name => @name))
  end
  
  def display
    puts "Member: #{@name.informal_name}"
    @house_periods.each do |p|
      puts "  start: #{p.from_date} #{p.from_why}, end: #{p.to_date} #{p.to_why}"    
    end    
  end

  def output_person(x)
    x.person(:id => "uk.org.publicwhip/person/#{@id}", :latestname => @name.informal_name) do
      @house_periods.each do |p|
        if p.current?
          x.office(:id => "uk.org.publicwhip/member/#{p.id}", :current => "yes")
        else
          x.office(:id => "uk.org.publicwhip/member/#{p.id}")
        end
      end
    end
  end

  def output_house_periods(x)
    @house_periods.each {|p| p.output(x)}
  end 

  def image(width, height)
    if @image_url
      conf = Configuration.new
      res = Net::HTTP::Proxy(conf.proxy_host, conf.proxy_port).get_response(@image_url)
      begin
        image = Magick::Image.from_blob(res.body)[0]
        image.resize_to_fit(width, height)
      rescue
        puts "WARNING: Could not load image #{@image_url}"
      end
    end
  end
  
  def small_image
    image(@@THUMB_WIDTH, @@THUMB_HEIGHT)
  end
  
  def big_image
    image(@@THUMB_WIDTH * 2, @@THUMB_HEIGHT * 2)
  end
end

# text is in day.month.year form (all numbers)
def parse_date(text)
  m = text.match(/([0-9]+).([0-9]+).([0-9]+)/)
  day = m[1].to_i
  month = m[2].to_i
  year = m[3].to_i
  Date.new(year, month, day)
end

def parse_end_date(text)
  # If no end_date is specified then the member is currently in parliament with a stupid end date
  if text == " " || text.nil?
    text = "31.12.9999"
  end
  parse_date(text)
end

def parse_start_reason(text)
  # If no start_reason is specified this means a general election
  if text == "" || text.nil?
    "general_election"
  else
    text
  end
end

i = 0
people = []
while i < data.size do
  name_text, division, state, start_date, start_reason, end_date, end_reason, party = data[i]
  
  name = Name.last_title_first(name_text)
  person = Person.new(name)

  start_date = parse_date(start_date)
  end_date = parse_end_date(end_date)
  start_reason = parse_start_reason(start_reason)
  person.add_house_period(:division => division, :party => party,
    :from_date => start_date, :to_date => end_date, :from_why => start_reason, :to_why => end_reason)
  i = i + 1
  # Process further start/end dates for this member
  while i < data.size && data[i][0] == name_text
    temp, division, state, start_date, start_reason, end_date, end_reason, party = data[i]
    start_date = parse_date(start_date)
    end_date = parse_end_date(end_date)
    start_reason = parse_start_reason(start_reason)
    person.add_house_period(:division => division, :party => party,
      :from_date => start_date, :to_date => end_date, :from_why => start_reason, :to_why => end_reason)
    i = i + 1
  end
  
  people << person
end

# Find person with the given name in the list of people. Returns nil if non found
def find_person(name, people)
  throw "name: #{name} doesn't have last name" if name.last == ""
  r = people.find_all do |p|
    p.name.first.downcase == name.first.downcase &&
      p.name.middle.downcase == name.middle.downcase &&
      p.name.last.downcase == name.last.downcase
  end
  if r.size == 0
    nil
  elsif r.size == 1
    r[0]
  else
    throw "More than one result for name: #{name.informal_name}"
  end
end

# Pick up photos of the current members

# Required to workaround long viewstates generated by .NET (whatever that means)
# See http://code.whytheluckystiff.net/hpricot/ticket/13
Hpricot.buffer_size = 262144

agent = WWW::Mechanize.new
agent.set_proxy(conf.proxy_host, conf.proxy_port)

def parse_person_page(sub_page, people)
  name = Name.last_title_first(sub_page.search("#txtTitle").inner_text.to_s[14..-1])
  content = sub_page.search('div#contentstart')
  
  # Grab image of member
  img_tag = content.search("img").first
  # If image is available
  if img_tag
    relative_image_url = img_tag.attributes['src']
    if relative_image_url != "images/top_btn.gif"
      image_url = sub_page.uri + URI.parse(relative_image_url)
    end
  end

  if image_url
    person = find_person(name, people)
    if person
      person.image_url = image_url
    else
      puts "WARNING: Skipping photo for #{name.informal_name} because they don't exist in the list of people"
    end
  end
end

# Go through current members of house
agent.get(conf.current_members_url).links[29..-4].each do |link|
  sub_page = agent.click(link)
  parse_person_page(sub_page, people)
end
# Go through former members of house and senate
agent.get(conf.former_members_url).links[29..-4].each do |link|
  sub_page = agent.click(link)
  parse_person_page(sub_page, people)
end

xml = File.open('pwdata/members/people.xml', 'w')
x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
x.instruct!
x.publicwhip do
  people.each do |p|
    p.output_person(x)
    p.small_image.write("pwdata/images/mps/#{p.id}.jpg") if p.small_image
    p.big_image.write("pwdata/images/mpsL/#{p.id}.jpg") if p.big_image
  end  
end
xml.close

xml = File.open('pwdata/members/all-members.xml', 'w')
x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
x.instruct!
x.publicwhip do
  people.each{|p| p.output_house_periods(x)}
end
xml.close

# And load up the database
system(conf.web_root + "/twfy/scripts/xml2db.pl --members --all --force")
system("cp -R pwdata/images/* " + conf.web_root + "/twfy/www/docs/images")

#people.each {|p| p.display}
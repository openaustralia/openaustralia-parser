$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'csv'
require 'date'
require 'builder'

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
  
  @@id = 10001
  
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
  name, division, state, start_date, start_reason, end_date, end_reason, party = data[i]
  
  name = Name.last_title_first(name)
  person = Person.new(name)

  start_date = parse_date(start_date)
  end_date = parse_end_date(end_date)
  start_reason = parse_start_reason(start_reason)
  person.add_house_period(:division => division, :party => party,
    :from_date => start_date, :to_date => end_date, :from_why => start_reason, :to_why => end_reason)
  i = i + 1
  # Process further start/end dates for this member
  while i < data.size && data[i][0].nil?
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

xml = File.open('pwdata/members/people.xml', 'w')
x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
x.instruct!
x.publicwhip do
  people.each do |p|
    p.output_person(x)
    #p.small_image.write("pwdata/images/mps/#{m.id_person}.jpg") if m.small_image
    #p.big_image.write("pwdata/images/mpsL/#{m.id_person}.jpg") if m.big_image
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
#system("cp -R pwdata/images/* " + conf.web_root + "/twfy/www/docs/images")

#people.each {|p| p.display}
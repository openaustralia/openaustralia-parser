require 'csv'
require 'date'

require 'people'
require 'person'
require 'name'

class PeopleCSVReader
  def PeopleCSVReader.read(filename)
    # Read in csv file of members data

    data = CSV.readlines(filename)
    # Remove the first two elements
    data.shift
    data.shift

    i = 0
    people = People.new
    while i < data.size do
      lastname, firstname, middlename, division, state, start_date, start_reason, end_date, end_reason, party = data[i]

      name = Name.new(:last => lastname, :first => firstname, :middle => middlename)
      person = Person.new(name)

      start_date = parse_date(start_date)
      end_date = parse_end_date(end_date)
      start_reason = parse_start_reason(start_reason)
      person.add_house_period(:division => division, :party => party,
        :from_date => start_date, :to_date => end_date, :from_why => start_reason, :to_why => end_reason)
      i = i + 1
      # Process further start/end dates for this member
      while i < data.size && data[i][0] == lastname && data[i][1] == firstname && data[i][2] == middlename
        temp1, temp2, temp3, division, state, start_date, start_reason, end_date, end_reason, party = data[i]
        start_date = parse_date(start_date)
        end_date = parse_end_date(end_date)
        start_reason = parse_start_reason(start_reason)
        person.add_house_period(:division => division, :party => party,
          :from_date => start_date, :to_date => end_date, :from_why => start_reason, :to_why => end_reason)
        i = i + 1
      end

      people << person
    end
    people
  end  

  private
  
  # text is in day.month.year form (all numbers)
  def PeopleCSVReader.parse_date(text)
    m = text.match(/([0-9]+).([0-9]+).([0-9]+)/)
    day = m[1].to_i
    month = m[2].to_i
    year = m[3].to_i
    Date.new(year, month, day)
  end

  def PeopleCSVReader.parse_end_date(text)
    # If no end_date is specified then the member is currently in parliament with a stupid end date
    if text == " " || text.nil?
      text = "31.12.9999"
    end
    parse_date(text)
  end

  def PeopleCSVReader.parse_start_reason(text)
    # If no start_reason is specified this means a general election
    if text == "" || text.nil?
      "general_election"
    else
      text
    end
  end
end

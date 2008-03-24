require 'csv'
require 'date_with_future'

require 'people'
require 'person'
require 'name'

class PeopleCSVReader
  def PeopleCSVReader.read(members_filename, ministers_filename)
    # Read in csv file of members data

    data = CSV.readlines(members_filename)
    # Remove the first two elements
    data.shift
    data.shift

    i = 0
    people = People.new
    while i < data.size do
      lastname, firstname, middlename, nickname, title, house, division, state, start_date, start_reason, end_date, end_reason, party = data[i]

      name = Name.new(:last => lastname, :first => firstname, :middle => middlename, :nick => nickname, :title => title)
      person = Person.new(name)

      start_date = parse_date(start_date)
      end_date = parse_end_date(end_date)
      start_reason = parse_start_reason(start_reason)
      person.add_period(:house => house, :division => division, :party => party,
        :from_date => start_date, :to_date => end_date, :from_why => start_reason, :to_why => end_reason)
      i = i + 1
      # Process further start/end dates for this member
      while i < data.size && data[i][0] == lastname && data[i][1] == firstname && data[i][2] == middlename && data[i][3] == nickname && data[i][4] == title
        temp1, temp2, temp3, temp4, temp5, house, division, state, start_date, start_reason, end_date, end_reason, party = data[i]
        start_date = parse_date(start_date)
        end_date = parse_end_date(end_date)
        start_reason = parse_start_reason(start_reason)
        person.add_period(:house => house, :division => division, :party => party,
          :from_date => start_date, :to_date => end_date, :from_why => start_reason, :to_why => end_reason)
        i = i + 1
      end

      people << person
    end
    read_ministers(ministers_filename, people)
    people
  end  

  private
  
  # Attaches ministerial information to people
  def PeopleCSVReader.read_ministers(filename, people)
    data = CSV.readlines(filename)
    # Remove the first two rows
    data.shift
    data.shift
    data.each do |line|
      name, from_date, to_date , position = line
      from_date = parse_date(from_date)
      if to_date == "" || to_date.nil?
        to_date = DateWithFuture.future
      else
        to_date = parse_date(to_date)
      end
      # Skip the line where we don't know the person
      if name != "??"
        n = Name.last_title_initials(name)
        person = people.find_person_by_name(n) if n
        throw "Can't find #{name}" if person.nil?
        person.add_minister_position(:from_date => from_date, :to_date => to_date, :position => position)
      end
    end
  end
  
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
      DateWithFuture.future
    else
      parse_date(text)
    end
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

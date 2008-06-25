require 'csv'
require 'ostruct'
require 'date_with_future'

require 'people'
require 'person'
require 'name'

class PeopleCSVReader
  def PeopleCSVReader.read_members(members_filename)
    # Read in csv file of members data

    data = CSV.readlines(members_filename)
    # Remove the first two elements
    data.shift
    data.shift

    data = data.map do |line|
      a = OpenStruct.new
      person_count, title, lastname, firstname, middlename, nickname, post_title, house, division, state, start_date, start_reason, end_date, end_reason, party = line
      # Ignore comment lines starting with '#'
      unless line[0] && line[0][0..0] == '#'
        party = parse_party(party)
        start_date = parse_date(start_date)
        end_date = parse_end_date(end_date)
        start_reason = parse_start_reason(start_reason)

        a.name = Name.new(:last => lastname, :first => firstname, :middle => middlename,
          :nick => nickname, :title => title, :post_title => post_title)
        throw "Division is undefined for #{a.name.full_name}" if house == "representatives" && division.nil?
        a.period_params = {:house => house, :division => division, :party => party,
            :from_date => start_date, :to_date => end_date, :from_why => start_reason, :to_why => end_reason}
        a
      end
    end
    data.compact!
    
    i = 0
    people = People.new
    while i < data.size do
      name = data[i].name
      person = Person.new(name)
      person.add_period(data[i].period_params)
      i = i + 1
      # Process further start/end dates for this member
      while i < data.size && data[i].name == name
        person.add_period(data[i].period_params)
        i = i + 1
      end

      people << person
    end
    people
  end
  
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
      n = Name.title_first_last(name)
      person = people.find_person_by_name_current_on_date(n, from_date) if n
      throw "Can't find #{name} for date #{from_date}" if person.nil?
      person.add_minister_position(:from_date => from_date, :to_date => to_date, :position => position)
    end
  end
  
  private
  
  def PeopleCSVReader.parse_party(party)
    case party
    when "LIB"
      "Liberal Party"
    when "ALP"
      "Australian Labor Party"
    when "NPA", "NP", "Nats"
      "National Party"
    when "AD"
      "Australian Democrats"
    when "IND"
      "Independent"
    when "CDP"
      "Christian Democratic Party"
    when "NCP", "CP"
      "National Country Party"
    when "GWA", "GRN", "AG"
      "Australian Greens"
    when "IND LIB"
      "Independent Liberal"
    when "CLP"
      "Country Liberal Party"
    when "FFP"
      "Family First Party"
    when "UNITE AP"
      "Unite Australia Party"
    when "NDP"
      "Nuclear Disarmament Party"
    when "PHON"
      "Pauline Hanson's One Nation Party"
    when "ANTI-SOC", "SPK", "CWM"
      # Do nothing
      party
    else
      throw "Unrecognised party: #{party}"
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

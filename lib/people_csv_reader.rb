require 'csv'
require 'ostruct'
require 'date_with_future'

require 'people'
require 'person'
require 'name'

class PeopleCSVReader
  
  # Ignores comment lines starting with '#'
  def PeopleCSVReader.read_raw_csv(filename)
    data = CSV.readlines(filename)
    data.delete_if {|line| line[0] && line[0][0..0] == '#'}
    data
  end
  
  def PeopleCSVReader.read_members(people_filename, members_filename)
    data = read_raw_csv(people_filename)
    data.shift
    data.shift

    people = People.new
    data.each do |line|
      person_count, title, lastname, firstname, middlename, nickname, post_title = line
      people << Person.new(Name.new(:last => lastname, :first => firstname, :middle => middlename,
        :nick => nickname, :title => title, :post_title => post_title))
    end
    
    data = read_raw_csv(members_filename)
    # Remove the first two elements
    data.shift
    data.shift

    data.each do |line|
      person_count, title, lastname, firstname, middlename, nickname, post_title, house, division, state, start_date, start_reason, end_date, end_reason, party = line
      party = parse_party(party)
      start_date = parse_date(start_date)
      end_date = parse_end_date(end_date)
      start_reason = parse_start_reason(start_reason)

      name = Name.new(:last => lastname, :first => firstname, :middle => middlename,
        :nick => nickname, :title => title, :post_title => post_title)
      throw "Division is undefined for #{a.name.full_name}" if house == "representatives" && division.nil?

      person = people.find_person_by_name(name)
      throw "Couldn't find person #{name.full_name}" if person.nil?
      person.add_period(:house => house, :division => division, :party => party,
          :from_date => start_date, :to_date => end_date, :from_why => start_reason, :to_why => end_reason)
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

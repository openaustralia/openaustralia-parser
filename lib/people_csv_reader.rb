# frozen_string_literal: true

require "csv"
require "ostruct"
require "date_with_future"
require "people"
require "person"
require "name"

class PeopleCSVReader
  # Ignores comment lines starting with '#'
  def self.read_raw_csv(filename)
    data = CSV.readlines(filename)
    data.delete_if { |line| line[0] && line[0][0..0] == "#" }
    data
  end

  def self.read_people(filename)
    data = read_raw_csv(filename)
    data.shift
    data.shift

    people = People.new
    data.each do |line|
      person_count, aph_id, name_text, birthday = line[0..3]
      name = Name.title_first_last(name_text)

      # You can specify multiple alternate names by filling out the next columns
      alternate_names = []
      line[4..].each do |t|
        alternate_names << Name.title_first_last(t) if !t.nil? && !t.empty?
      end
      begin
        parsed_birthday = (birthday ? Date.strptime(birthday) : nil)
      rescue Date::Error
        raise "Birthday #{birthday} not valid for #{name_text}"
      end
      people << Person.new(
        name: name, alternate_names: alternate_names,
        count: person_count.to_i,
        birthday: parsed_birthday,
        aph_id: aph_id
      )
    end
    people
  end

  def self.read_members_csv(people, filename, house)
    data = read_raw_csv(filename)
    # Remove the first two elements
    data.shift
    data.shift

    data.each do |line|
      member_count, person_count, name_text, division, state, start_date, start_reason, end_date, end_reason, party = line
      party = parse_party(party)
      start_date = parse_date(start_date)
      end_date = parse_end_date(end_date)
      start_reason = parse_start_reason(start_reason)
      valid_states = %w[NSW Tasmania WA Queensland Victoria SA NT ACT]
      state = "Tasmania" if ["Tas.", "Tas"].include?(state)
      state = "Victoria" if ["Vic.", "Vic"].include?(state)
      state = "Queensland" if %w[Qld QLD].include?(state)
      raise "State #{state} is not a valid. Allowed values are #{valid_states.join(', ')}" unless valid_states.member?(state)

      name = Name.title_first_last(name_text)
      raise "Division is undefined for #{name.full_name}" if house.representatives? && division.nil?

      matches = people.find_people_by_name(name)
      raise "Couldn't find person #{name.full_name}" if matches.empty?

      if matches.size > 1
        raise "More than one match for name #{name.full_name} found" unless person_count

        # In a situation where several people match we use the "person count" field to disambiguate
        person = people.find_person_by_count(person_count.to_i)
      else
        person = matches.first
      end

      person.add_period(house: house, division: division, state: state, party: party,
                        from_date: start_date, to_date: end_date, from_why: start_reason, to_why: end_reason, count: member_count.to_i)
    end

    people
  end

  def self.read_members(people_filename = "#{File.dirname(__FILE__)}/../data/people.csv",
                        representatives_filename = "#{File.dirname(__FILE__)}/../data/representatives.csv",
                        senators_filename = "#{File.dirname(__FILE__)}/../data/senators.csv")
    people = read_people(people_filename)
    read_members_csv(people, representatives_filename, House.representatives)
    read_members_csv(people, senators_filename, House.senate)
  end

  # Attaches ministerial information to people
  def self.read_ministers(people, filename)
    data = CSV.readlines(filename)
    # Remove the first two rows
    data.shift
    data.shift
    data.each do |line|
      name, from_date, to_date, position = line
      from_date = parse_date(from_date)
      to_date = if to_date == "" || to_date.nil?
                  DateWithFuture.future
                else
                  parse_date(to_date)
                end
      n = Name.title_first_last(name)
      person = people.find_person_by_name_current_on_date(n, from_date) if n
      raise "Can't find #{name} for date #{from_date}" if person.nil?

      person.add_minister_position(from_date: from_date, to_date: to_date, position: position)
    end
  end

  def self.read_all_ministers(people, ministers_filename = "#{File.dirname(__FILE__)}/../data/ministers.csv",
                              shadow_ministers_filename = "#{File.dirname(__FILE__)}/../data/shadow-ministers.csv")
    read_ministers(people, ministers_filename)
    read_ministers(people, shadow_ministers_filename)
  end

  def self.parse_party(party)
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
    when "DLP"
      "Democratic Labor Party"
    when "PUP"
      "Palmer United Party"
    when "LNP"
      "Liberal National Party"
    when "LDP"
      "Liberal Democratic Party"
    when "MEP"
      "Australian Motoring Enthusiast Party"
    when "NXT"
      "Nick Xenophon Team"
    when "DHJP"
      "Derryn Hinch's Justice Party"
    when "AC"
      "Australian Conservatives"
    when "KAP"
      "Katter's Australian Party"
    when "UAP"
      "United Australia Party"
    when "CA"
      "Centre Alliance"
    when "JLN"
      "Jacqui Lambie Network"
    when "AV"
      "Australia's Voice" # Senator Fatima Payman's party
    when "GRPF"
      "Gerard Rennick People First" # Senator Gerard Rennick's party
    when "ANTI-SOC", "SPK", "CWM", "PRES", "DPRES"
      # Do nothing
      party
    else
      raise "Unrecognised party: '#{party}', check mapping in people_csv_reader.rb"
    end
  end

  # text is in day.month.year form (all numbers)
  def self.parse_date(text)
    m = text.match(/([0-9]+).([0-9]+).([0-9]+)/)
    day = m[1].to_i
    month = m[2].to_i
    year = m[3].to_i
    Date.new(year, month, day)
  end

  def self.parse_end_date(text)
    # If no end_date is specified then the member is currently in parliament with a stupid end date
    if text == " " || text.nil?
      DateWithFuture.future
    else
      parse_date(text)
    end
  end

  def self.parse_start_reason(text)
    # If no start_reason is specified this means a general election
    if text == "" || text.nil?
      "general_election"
    else
      text
    end
  end
end

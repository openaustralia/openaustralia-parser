require 'people_csv_reader'
require 'people_xml_writer'
require 'people_image_downloader'
require 'house'

class People < Array
  def initialize
    # A hash from lastname to all people that have the lastname (used for speeding up name lookup)
    @last_names = {}
  end

  # Override method to populate @last_names
  def <<(person)
    person.all_names.each do |name|
      @last_names[name.last] = [] unless @last_names.has_key?(name.last)
      @last_names[name.last] << person unless @last_names[name.last].include?(person)
    end
    super
  end

  # Methods that return Person object

  # Returns nil if non found. raises exception if more than one match
  def find_person_by_name(name)
    matches = find_people_by_name(name)
    raise "More than one match for name #{name.full_name} found" if matches.size > 1

    matches[0] if matches.size == 1
  end

  def find_person_by_aph_id(aph_id)
    find { |p| p.aph_id == aph_id }
  end

  def find_person_by_count(count)
    find { |p| p.person_count == count }
  end

  def find_person_by_name_current_on_date(name, date)
    matches = find_people_by_name_current_on_date(name, date)
    raise "More than one match for name #{name.full_name} found" if matches.size > 1

    matches[0] if matches.size == 1
  end

  def find_person_by_name_and_birthday(name, birthday)
    matches = find_people_by_name_and_birthday(name, birthday)
    raise "More than one match for name #{name.full_name} with birthday #{birthday} found" if matches.size > 1

    matches[0] if matches.size == 1
  end

  def find_people_by_name_and_birthday(name, birthday)
    # Only use the birthday to match if it has been set
    find_people_by_name(name).find_all { |m| m.birthday.nil? || m.birthday == birthday }
  end

  # Returns all the people that match a particular name and have current senate/house of representatives positions on the date
  def find_people_by_name_current_on_date(name, date)
    find_people_by_name(name).find_all { |p| p.current_position_on_date?(date) }
  end

  def find_people_by_name(name)
    potential = find_people_by_lastname(name.last)
    if potential.nil?
      []
    elsif potential.length == 1
      potential
    else
      potential.find_all { |p| p.name_matches?(name) }
    end
  end

  def find_people_by_lastname(lastname)
    @last_names[lastname]
  end

  # Methods that return Period objects

  def house_speaker(date)
    member = find_members_current_on(date, House.representatives).find { |m| m.house_speaker? }
    raise "Could not find house speaker for date #{date}" if member.nil?

    member
  end

  def senate_president(date)
    member = find_members_current_on(date, House.senate).find { |m| m.senate_president? }
    raise "Could not find senate president for date #{date}" if member.nil?

    member
  end

  def deputy_senate_president(date)
    member = find_members_current_on(date, House.senate).find { |m| m.deputy_senate_president? }
    raise "Could not find deputy senate president for date #{date}" if member.nil?

    member
  end

  def deputy_house_speaker(date)
    member = find_members_current_on(date, House.representatives).find { |m| m.deputy_house_speaker? }
    raise "Could not find deputy house speaker for date #{date}" if member.nil?

    member
  end

  def find_member_by_name_current_on_date(name, date, house)
    matches = find_members_by_name_current_on_date(name, date, house)
    # If multiple matches, try to refine with person's initials
    if matches.size > 1
      refined_matches = []
      matches.each do |m|
        m.person.all_names.each do |n|
          if n.real_initials[0..2] == name.real_initials[0..2]
            found = nil
            refined_matches.each do |x|
              found = x.person if x.person == m.person
            end
            refined_matches << m if found.nil?
          end
        end
      end
      if refined_matches.size == 0
        # Try again with just the first initial
        matches.each do |m|
          m.person.all_names.each do |n|
            if n.real_initials[0..1] == name.real_initials[0..1]
              found = nil
              refined_matches.each do |x|
                found = x.person if x.person == m.person
              end
              refined_matches << m if found.nil?
            end
          end
        end
      end
      if refined_matches.size == 1
        refined_matches[0]
      else
        raise "More than one match for name #{name.full_name} #{name.real_initials} found in #{house.name}"
      end
    elsif matches.size == 1
      matches[0]
    end
  end

  def find_members_by_name(name)
    find_people_by_name(name).map { |p| p.periods }.flatten
  end

  def find_members_by_name_current_on_date(name, date, house)
    find_members_by_name(name).find_all { |m| m.current_on_date?(date) && m.house == house }
  end

  def find_current_members(house)
    all_periods_in_house(house).find_all { |m| m.current? }
  end

  def find_members_current_on(date, house)
    all_periods_in_house(house).find_all { |m| m.current_on_date?(date) }
  end

  # End of methods that return Period objects

  # All the electoral divisions that have ever existed (even if they don't exist anymore)
  def divisions
    all_periods_in_house(House.representatives).map { |p| p.division }.uniq
  end

  # Facade for readers and writers
  def write_xml(people_filename, members_filename, senators_filename, ministers_filename, divisions_filename)
    PeopleXMLWriter.write(self, people_filename, members_filename, senators_filename, ministers_filename, divisions_filename)
  end

  def download_images(small_image_dir, large_image_dir)
    downloader = PeopleImageDownloader.new
    downloader.download(self, small_image_dir, large_image_dir)
  end

  def all_periods_in_house(house)
    map { |p| p.periods }.flatten.find_all { |p| p.house == house }
  end
end

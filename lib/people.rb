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
    @last_names[person.name.last] = [] unless @last_names.has_key?(person.name.last)
    @last_names[person.name.last] << person
    super
  end
  
  # Methods that return Person object
  
  # Returns nil if non found. Throws exception if more than one match
  def find_person_by_name(name)
    matches = find_people_by_name(name)
    throw "More than one match for name #{name.full_name} found" if matches.size > 1
    matches[0] if matches.size == 1
  end
  
  def find_person_by_count(count)
    find{|p| p.person_count == count}
  end  

  def find_person_by_name_current_on_date(name, date)
    matches = find_people_by_name_current_on_date(name, date)
    throw "More than one match for name #{name.full_name} found" if matches.size > 1
    matches[0] if matches.size == 1
  end

  def find_person_by_name_and_birthday(name, birthday)
    matches = find_people_by_name(name)
    return matches[0] if matches.size == 1
    return nil if matches.size == 0

    #more than one match found, use birthday
    return matches.find {|m| m.birthday == birthday}
  end

  # Returns all the people that match a particular name and have current senate/house of representatives positions on the date
  def find_people_by_name_current_on_date(name, date)
    find_people_by_name(name).find_all {|p| p.current_position_on_date?(date)} 
  end
  
  def find_people_by_name(name)
    potential = find_people_by_lastname(name.last)
    if potential.nil?
      []
    else
      potential.find_all{|p| name.matches?(p.name)}
    end
  end
  
  def find_people_by_lastname(lastname)
    @last_names[lastname]
  end
  
  # Methods that return Period objects
  
  def house_speaker(date)
    member = find_members_current_on(date, House.representatives).find {|m| m.house_speaker?}
    throw "Could not find house speaker for date #{date}" if member.nil?
    member
  end
  
  def senate_president(date)
    member = find_members_current_on(date, House.senate).find {|m| m.senate_president?}
    throw "Could not find senate president for date #{date}" if member.nil?
    member
  end
  
  def deputy_senate_president(date)
    member = find_members_current_on(date, House.senate).find {|m| m.deputy_senate_president?}
    throw "Could not find deputy senate president for date #{date}" if member.nil?
    member
  end
  
  def deputy_house_speaker(date)
    member = find_members_current_on(date, House.representatives).find {|m| m.deputy_house_speaker?}
    throw "Could not find deputy house speaker for date #{date}" if member.nil?
    member
  end

  def find_member_by_name_current_on_date(name, date, house)
    matches = find_members_by_name_current_on_date(name, date, house)
    throw "More than one match for name #{name.full_name} found in #{house.name}" if matches.size > 1
    matches[0] if matches.size == 1
  end
  
  def find_members_by_name_current_on_date(name, date, house)
    find_members_current_on(date, house).find_all {|m| name.matches?(m.person.name)}
  end
  
  def find_current_members(house)
    all_periods_in_house(house).find_all {|m| m.current?}
  end
  
  def find_members_current_on(date, house)
    all_periods_in_house(house).find_all {|m| m.current_on_date?(date)}
  end
  
  # End of methods that return Period objects
  
  # Facade for readers and writers
  def write_xml(people_filename, members_filename, senators_filename, ministers_filename)
    PeopleXMLWriter.write(self, people_filename, members_filename, senators_filename, ministers_filename)
  end
  
  def download_images(small_image_dir, large_image_dir)
    downloader = PeopleImageDownloader.new
    downloader.download(self, small_image_dir, large_image_dir)
  end
  
  def all_periods
    map {|person| person.periods}.flatten
  end
  
  def all_periods_in_house(house)
    all_periods.find_all{|p| house.representatives? ? p.representative? : p.senator?}
  end
end

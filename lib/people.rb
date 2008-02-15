require 'people_csv_reader'
require 'people_xml_reader'
require 'people_xml_writer'
require 'people_image_downloader'

class People < Array
  
  def initialize
    @all_house_periods = []
  end
  
  # Override method to populate @all_house_periods
  def <<(person)
    @all_house_periods.concat(person.house_periods)
    super
  end
  
  def find_by_first_last_name(name)
    find_all do |p|
      p.name.first.downcase == name.first.downcase &&
        p.name.last.downcase == name.last.downcase
    end
  end

  def find_by_first_middle_last_name(name)
    find_all do |p|
      p.name.first.downcase == name.first.downcase &&
        p.name.middle.downcase == name.middle.downcase &&
        p.name.last.downcase == name.last.downcase
    end
  end

  # Find person with the given name. Returns nil if non found
  def find_by_name(name)
    throw "name: #{name} doesn't have last name" if name.last == ""
    r = find_by_first_last_name(name)
    if r.size == 0
      nil
    elsif r.size == 1
      r[0]
    else
      # Multiple results so use the middle name to narrow the search
      r = find_by_first_middle_last_name(name)
      if r.size == 0
        nil
      elsif r.size == 1
        r[0]
      else
        throw "More than one result for name: #{name.informal_name}"
      end
    end
  end
  
  def find_member_id_by_fullname(name, date)
    names = name.split(' ')
    names.delete("Mr")
    names.delete("Mrs")
    names.delete("Ms")
    names.delete("Dr")
    if names.size == 2
      firstname = names[0]
      lastname = names[1]
    elsif names.size == 1
      firstname = ""
      lastname = names[0]
    else
      throw "Can't parse the name #{name}"
    end
    find_member_id_by_name(firstname, lastname, date)
  end
  
  def find_house_period_by_id(id)
    @all_house_periods.find{|p| p.id == id}
  end
  
  # Facade for readers and writers
  def People.read_csv(filename)
    PeopleCSVReader.read(filename)
  end
  
  def People.read_xml(people_filename, members_filename)
    PeopleXMLReader.read(people_filename, members_filename)
  end
  
  def write_xml(people_filename, members_filename)
    PeopleXMLWriter.write(self, people_filename, members_filename)
  end
  
  def download_images(small_image_dir, large_image_dir)
    downloader = PeopleImageDownloader.new
    downloader.download(self, small_image_dir, large_image_dir)
  end
  
  private
  
  def find_member_id_by_name(firstname, lastname, date)
    matches = find_members_by_name(firstname, lastname, date)
    throw "More than one match for member based on first name (#{firstname}) and last name #{lastname}" if matches.size > 1
    throw "No match for member found" if matches.size == 0
    matches[0].id
  end

  def all_house_periods_falling_on_date(date)
    @all_house_periods.find_all do |m|
      date >= m.from_date && date <= m.to_date
    end
  end
  
  def find_members_by_lastname(lastname, date)
    all_house_periods_falling_on_date(date).find_all do |m|
      m.person.name.last.downcase == lastname.downcase
    end
  end

  # If firstname is empty will just check by lastname
  def find_members_by_name(firstname, lastname, date)
    # First checking if there is an unambiguous match by lastname which allows
    # an amount of variation in first name: ie Tony vs Anthony
    matches = find_members_by_lastname(lastname, date)
    if firstname != "" && matches.size > 1
      matches = all_house_periods_falling_on_date(date).find_all do |m|
        m.person.name.first.downcase == firstname.downcase && m.person.name.last.downcase == lastname.downcase
      end
    end
    matches
  end
end

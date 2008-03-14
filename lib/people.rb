require 'people_csv_reader'
require 'people_xml_writer'
require 'people_image_downloader'

class People < Array
  
  def initialize
    @all_periods = []
  end
  
  # Override method to populate @all_house_periods
  def <<(person)
    @all_periods.concat(person.periods)
    super
  end
  
  # Returns nil if non found. Throws exception if more than one match
  def find_person_by_name(name)
    matches = find_people_by_name(name)
    throw "More than one match for name #{name.full_name} found" if matches.size > 1
    matches[0] if matches.size == 1
  end
  
  def find_people_by_name(name)
    find_all{|p| name.matches?(p.name)}
  end    
  
  # Returns the house members that are members on the given date
  def find_house_members_current_on(date)
    all_house_periods.find_all do |m|
      date >= m.from_date && date <= m.to_date
    end
  end
  
  def find_house_period_by_id(id)
    all_house_periods.find{|p| p.id == id}
  end
  
  # Facade for readers and writers
  def People.read_csv(members_filename, ministers_filename)
    PeopleCSVReader.read(members_filename, ministers_filename)
  end
  
  def write_xml(people_filename, members_filename)
    PeopleXMLWriter.write(self, people_filename, members_filename)
  end
  
  def download_images(small_image_dir, large_image_dir)
    downloader = PeopleImageDownloader.new
    downloader.download(self, small_image_dir, large_image_dir)
  end
  
  private
  
  def all_house_periods
    @all_periods.find_all{|p| p.house == "representatives"}
  end
end

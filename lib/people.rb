require 'people_csv_reader'
require 'people_xml_writer'
require 'people_image_downloader'

class People < Array
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
  
  # Facade for readers and writers
  def People.read_csv(filename)
    PeopleCSVReader.read(filename)
  end
  
  def write_people_xml(filename)
    PeopleXMLWriter.write_people(self, filename)    
  end

  def write_members_xml(filename)
    PeopleXMLWriter.write_members(self, filename)    
  end
  
  def download_images(small_image_dir, large_image_dir)
    downloader = PeopleImageDownloader.new
    downloader.download(self, small_image_dir, large_image_dir)
  end
end

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
    
  def write_xml
    write_people_xml('pwdata/members/people.xml')
    write_images("pwdata/images/mps", "pwdata/images/mpsL")
    write_members_xml('pwdata/members/all-members.xml')
  end
  
  def write_members_xml(filename)
    xml = File.open(filename, 'w')
    x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
    x.instruct!
    x.publicwhip do
      each{|p| p.output_house_periods(x)}
    end
    xml.close
  end
  
  def write_images(small_image_dir, large_image_dir)
    each do |p|
      p.small_image.write(small_image_dir + "/#{p.id}.jpg") if p.small_image
      p.big_image.write(large_image_dir + "/#{p.id}.jpg") if p.big_image
    end
  end
  
  def write_people_xml(filename)
    xml = File.open(filename, 'w')
    x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
    x.instruct!
    x.publicwhip do
      each do |p|
        p.output_person(x)
      end  
    end
    xml.close
  end
end

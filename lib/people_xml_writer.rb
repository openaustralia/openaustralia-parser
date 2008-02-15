require 'rubygems'
require 'builder'

class PeopleXMLWriter
  def PeopleXMLWriter.write_members(people, filename)
    xml = File.open(filename, 'w')
    x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
    x.instruct!
    x.publicwhip do
      people.each do |person|
        person.house_periods.each do |period|
          x.member(:id => "uk.org.publicwhip/member/#{period.id}",
            :house => "commons", :title => person.name.title, :firstname => person.name.first,
            :lastname => person.name.last, :constituency => period.division, :party => period.party,
            :fromdate => period.from_date, :todate => period.to_date, :fromwhy => period.from_why, :towhy => period.to_why)
        end
      end
    end
    xml.close
  end
  
  def PeopleXMLWriter.write_images(people, small_image_dir, large_image_dir)
    people.each do |p|
      p.small_image.write(small_image_dir + "/#{p.id}.jpg") if p.small_image
      p.big_image.write(large_image_dir + "/#{p.id}.jpg") if p.big_image
    end
  end

  def PeopleXMLWriter.write_people(people, filename)
    xml = File.open(filename, 'w')
    x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
    x.instruct!
    x.publicwhip do
      people.each do |person|
        x.person(:id => "uk.org.publicwhip/person/#{person.id}", :latestname => person.name.informal_name) do
          person.house_periods.each do |period|
            if period.current?
              x.office(:id => "uk.org.publicwhip/member/#{period.id}", :current => "yes")
            else
              x.office(:id => "uk.org.publicwhip/member/#{period.id}")
            end
          end
        end
      end  
    end
    xml.close
  end
end
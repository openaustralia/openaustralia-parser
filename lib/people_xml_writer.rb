require 'rubygems'
require 'builder_alpha_attributes'
require 'configuration'

class PeopleXMLWriter
  
  def PeopleXMLWriter.write(people, people_filename, members_filename, senators_filename, ministers_filename)
    conf = Configuration.new

    write_people(people, people_filename)
    write_members(people, members_filename)
    write_senators(people, senators_filename)
    write_ministers(people, ministers_filename)
  end
  
  def PeopleXMLWriter.write_ministers(people, filename)
    xml = File.open(filename, 'w')
    x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
    x.instruct!
    x.publicwhip do
      people.each do |person|
        person.minister_positions.each do |p|
          # TODO: Add "dept" and "source"
          x.ministerofficegroup do
            x.moffice(:id => p.id, :name => person.name.full_name,
              :matchid => person.periods.first.id, :position => p.position,
              :fromdate => p.from_date, :todate => p.to_date, :dept => "", :source => "")
          end
        end  
      end
    end
    xml.close
  end
  
  def PeopleXMLWriter.write_members(people, filename)
    conf = Configuration.new
    
    xml = File.open(filename, 'w')
    x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
    x.instruct!
    x.publicwhip do
      if conf.write_xml_representatives
        people.each do |person|
          person.house_periods.each do |period|
            x.member(:id => period.id,
              :house => "commons", :title => period.person.name.title, :firstname => period.person.name.first,
              :lastname => period.person.name.last, :constituency => period.division, :party => period.party,
              :fromdate => period.from_date, :todate => period.to_date, :fromwhy => period.from_why, :towhy => period.to_why)
          end
        end
      end
    end
    xml.close
  end

  def PeopleXMLWriter.write_senators(people, filename)
    conf = Configuration.new
    
    xml = File.open(filename, 'w')
    x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
    x.instruct!
    x.publicwhip do
      if conf.write_xml_senators
        people.each do |person|
          person.senate_periods.each do |period|
            x.lord(:id => period.id,
              :house => "lords", :title => period.person.name.title, :forenames => period.person.name.first,
              :lordname => period.person.name.last, :lordofname => period.state, :affiliation => period.party,    
              :fromdate => period.from_date, :todate => period.to_date, :fromwhy => period.from_why, :towhy => period.to_why)
          end
        end
      end
    end
    xml.close
  end
  
  def PeopleXMLWriter.write_people(people, filename)
    xml = File.open(filename, 'w')
    x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
    x.instruct!
    x.publicwhip do
      people.each do |person|
        x.person(:id => person.id, :latestname => person.name.informal_name) do
          person.periods.each do |period|
            if period.current?
              x.office(:id => period.id, :current => "yes")
            else
              x.office(:id => period.id)
            end
          end
          person.minister_positions.each do |p|
            if p.current?
              x.office(:id => p.id, :current => "yes")
            else
              x.office(:id => p.id)
            end
          end
        end
      end  
    end
    xml.close
  end
end
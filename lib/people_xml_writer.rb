require 'builder_alpha_attributes'
require 'configuration'

class PeopleXMLWriter
  
  def PeopleXMLWriter.write(people, people_filename, members_filename, senators_filename, ministers_filename, divisions_filename)
    conf = Configuration.new

    write_people(people, people_filename)
    write_members(people, members_filename, House.representatives)
    write_members(people, senators_filename, House.senate)
    write_ministers(people, ministers_filename)
    File.open(divisions_filename, 'w') {|f| write_divisions(people, f)}
  end
  
  def self.write_divisions(people, output)
    x = Builder::XmlMarkup.new(:target => output, :indent => 2)
    x.divisions do
      people.divisions.each_with_index do |division, index|
        x.division(:fromdate => "1000-01-01", :id => "uk.org.publicwhip/cons/#{index + 1}", :todate => "9999-12-31") do
          x.name(:text => division)
        end        
      end
    end
  end
  
  def PeopleXMLWriter.write_ministers(people, filename)
    conf = Configuration.new
    
    xml = File.open(filename, 'w')
    x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
    x.instruct!
    x.ministers do
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
  
  def PeopleXMLWriter.write_members(people, filename, house)
    conf = Configuration.new
    
    xml = File.open(filename, 'w')
    x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
    x.instruct!
    x.members do
      people.each do |person|
        person.periods.each do |period|
          if period.house == house
            x.member(:id => period.id,
              :house => house, :title => period.person.name.title, :firstname => period.person.name.first,
              :lastname => period.person.name.last, :division => period.division, :party => period.party,
              :fromdate => period.from_date, :todate => period.to_date, :fromwhy => period.from_why, :towhy => period.to_why)
          end
        end
      end
    end
    xml.close
  end
  
  def PeopleXMLWriter.write_people(people, filename)
    conf = Configuration.new
    
    xml = File.open(filename, 'w')
    x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
    x.instruct!
    x.people do
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
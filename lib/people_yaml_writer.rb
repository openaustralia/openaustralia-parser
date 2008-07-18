class PeopleYamlWriter
  def PeopleYamlWriter.write(people, filename = "#{File.dirname(__FILE__)}/../data/people.yml")
    yaml_people = people.map do |person|
      #@periods = []
      #@minister_positions = []
      a = {"id" => person.person_count, "name" => person.name.full_name}
      a["alternate_names"] = person.alternate_names.map{|n| n.full_name} unless person.alternate_names.empty?
      a["birthday"] = person.birthday unless person.birthday.nil?
      representative = person.house_periods.map do |p|
        {"from" => {"date" => p.from_date, "why" => p.from_why.to_s}, "to" => {"date" => p.to_date, "why" => p.to_why.to_s},
          "division" => p.division.to_s, "state" => p.state.to_s, "party" => p.party, "id" => p.count}
      end
      a["representative"] = representative unless representative.empty?
      a
    end
    File.open(filename, 'w' ) do |out|
      YAML.dump(yaml_people, out)
    end
  end
end

require 'people_csv_reader'

puts "Reading members data..."
people = PeopleCSVReader.read_members
PeopleCSVReader.read_all_ministers(people)
PeopleYamlWriter.write(people)


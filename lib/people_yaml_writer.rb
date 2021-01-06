# frozen_string_literal: true

class PeopleYamlWriter
  def self.write(people, filename = "#{File.dirname(__FILE__)}/../data/people.yml")
    yaml_people = people.map do |person|
      # @minister_positions = []
      a = { "id" => person.person_count, "name" => person.name.full_name }
      a["alternate_names"] = person.alternate_names.map(&:full_name) unless person.alternate_names.empty?
      a["birthday"] = person.birthday unless person.birthday.nil?
      representative = person.house_periods.map do |p|
        b = { "from" => { "date" => p.from_date, "why" => p.from_why.to_s },
              "division" => p.division.to_s, "state" => p.state.to_s, "party" => p.party, "id" => p.count }
        b["to"] = { "date" => p.to_date, "why" => p.to_why.to_s } unless p.current?
        b
      end
      a["representative"] = representative unless representative.empty?
      senator = person.senate_periods.map do |p|
        b = { "from" => { "date" => p.from_date, "why" => p.from_why.to_s },
              "state" => p.state.to_s, "party" => p.party, "id" => p.count }
        b["to"] = { "date" => p.to_date, "why" => p.to_why.to_s } unless p.current?
        b
      end
      a["senator"] = senator unless senator.empty?
      minister = person.minister_positions.map do |p|
        b = { "from" => p.from_date, "position" => p.position.to_s, "id" => p.minister_count }
        b["to"] = p.to_date unless p.current?
        b
      end
      a["minister"] = minister unless minister.empty?
      a
    end
    File.open(filename, "w") do |out|
      YAML.dump(yaml_people, out)
    end
  end
end

require "people_csv_reader"

puts "Reading members data..."
people = PeopleCSVReader.read_members
PeopleCSVReader.read_all_ministers(people)
PeopleYamlWriter.write(people)

# frozen_string_literal: true

require "nokogiri"
# require "builder_alpha_attributes" # BRW: commented out because it doesn't work in ruby3

class PeopleXMLWriter
  def self.write(people:, people_filename:, members_filename:, senators_filename:, ministers_filename:, divisions_filename:)
    write_people(people, people_filename)
    write_members(people, members_filename)
    write_senators(people, senators_filename)
    write_ministers(people, ministers_filename)
    # File.open(divisions_filename, "w") { |f| write_divisions(people, f) }
  end

  def self.write_divisions(people, output)
    x = Builder::XmlMarkup.new(target: output, indent: 2)
    x.divisions do
      people.divisions.each_with_index do |division, index|
        x.division(fromdate: "1000-01-01", id: "uk.org.publicwhip/cons/#{index + 1}", todate: "9999-12-31") do
          x.name(text: division)
        end
      end
    end
  end

  def self.write_ministers(people, filename)
    xml = File.open(filename, "w")
    # x = Builder::XmlMarkup.new(target: xml, indent: 1)
    x = Nokogiri::XML::Builder.new(encoding: "UTF-8")
    # x.instruct!
    x.ministers do
      people.each do |person|
        person.minister_positions.each do |p|
          x.ministerofficegroup do
            x.moffice(
              id: p.id,
              name: person.name.full_name,
              matchid: person.periods.first.id,
              position: p.position,
              fromdate: p.from_date,
              todate: p.to_date,
              # TODO: Add "dept" and "source"
              dept: "",
              source: ""
            )
          end
        end
      end
    end
    xml.write(x.to_xml)
    xml.close
  end

  # This is based on the enum in the database schema
  VALID_FROM_WHY = %w[
    unknown general_election by_election changed_party
    reinstated appointed devolution election accession
    regional_election replaced_in_region became_presiding_officer
  ].freeze
  VALID_TO_WHY = %w[
    unknown still_in_office general_election
    general_election_standing general_election_not_standing
    changed_party died declared_void resigned disqualified
    became_peer devolution dissolution retired regional_election
    became_presiding_officer
  ].freeze

  # Discovered that mysql was silently dropping values for these fields
  # that weren't valid enum values rather than erroring. The newer version
  # of mysql that we're using now does error. So, to maintain compatibility
  # strip out "bad" values.
  # TODO: Update the openaustralia.org.au web app to handle new enum values
  def self.limit_from_why(from_why)
    VALID_FROM_WHY.include?(from_why) ? from_why : "unknown"
  end

  def self.limit_to_why(to_why)
    VALID_TO_WHY.include?(to_why) ? to_why : "unknown"
  end

  def self.write_members(people, filename)
    xml = File.open(filename, "w")
    # x = Builder::XmlMarkup.new(target: xml, indent: 1)
    x = Nokogiri::XML::Builder.new(encoding: "UTF-8")
    # x.instruct!
    x.members do
      people.each do |person|
        person.house_periods.each do |period|
          from_why = limit_from_why(period.from_why)
          to_why = limit_to_why(period.to_why)
          x.member(id: period.id,
                   house: "representatives", title: period.person.name.title, firstname: period.person.name.first,
                   lastname: period.person.name.last, division: period.division, party: period.party,
                   fromdate: period.from_date, todate: period.to_date, fromwhy: from_why, towhy: to_why)
        end
      end
    end
    xml.write(x.to_xml)
    xml.close
  end

  def self.write_senators(people, filename)
    xml = File.open(filename, "w")
    # x = Builder::XmlMarkup.new(target: xml, indent: 1)
    x = Nokogiri::XML::Builder.new(encoding: "UTF-8")
    # x.instruct!
    x.members do
      people.each do |person|
        person.senate_periods.each do |period|
          from_why = limit_from_why(period.from_why)
          to_why = limit_to_why(period.to_why)
          x.member(id: period.id,
                   house: "senate", title: period.person.name.title, firstname: period.person.name.first,
                   lastname: period.person.name.last, division: period.state, party: period.party,
                   fromdate: period.from_date, todate: period.to_date, fromwhy: from_why, towhy: to_why)
        end
      end
    end
    xml.write(x.to_xml)
    xml.close
  end

  def self.write_people(people, filename)
    xml = File.open(filename, "w")

    # x = Builder::XmlMarkup.new(target: xml, indent: 1)
    x = Nokogiri::XML::Builder.new(encoding: "UTF-8")
    # x.instruct!
    x.people do
      people.each do |person|
        x.person(id: person.id, latestname: person.name.informal_name) do
          person.house_periods.each do |period|
            if period.current?
              x.office(id: period.id, current: "yes")
            else
              x.office(id: period.id)
            end
          end
          person.senate_periods.each do |period|
            if period.current?
              x.office(id: period.id, current: "yes")
            else
              x.office(id: period.id)
            end
          end
          person.minister_positions.each do |p|
            if p.current?
              x.office(id: p.id, current: "yes")
            else
              x.office(id: p.id)
            end
          end
        end
      end
    end
    xml.write(x.to_xml)
    xml.close
  end
end

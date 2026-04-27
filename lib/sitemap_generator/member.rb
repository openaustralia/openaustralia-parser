class SitemapGenerator
  class Member < ActiveRecord::Base
    self.table_name = "member"

    def full_name
      "#{first_name} #{last_name}"
    end

    def self.find_all_person_ids
      Member.select(:person_id).group("person_id").map(&:person_id)
    end

    # Find the most recent member for the given person_id
    def self.find_most_recent_by_person_id(person_id)
      Member.where(person_id: person_id).order("entered_house DESC").first
    end

    # Returns the unique url for this member.
    # Obviously this doesn't really belong in the model but, you know, for the time being...
    # URLs without the initial http://www.openaustralia.org bit
    def url
      case house
      when 1
        house_url = "mp"
      when 2
        house_url = "senator"
      else
        throw "Unexpected value for house"
      end
      # The url is made up of the full_name, constituency and house
      # TODO: Need to correctly encode the urls
      "/#{house_url}/#{encode_name(full_name)}/#{encode_name(constituency)}"
    end

    # Encode names and constituencies (for URLs) in the following way
    def encode_name(text)
      text.downcase.tr(" ", "_")
    end
  end
end

class SitemapGenerator
  class Hansard < ActiveRecord::Base
    self.table_name = "hansard"
    self.primary_key = "epobject_id"

    has_many :comments, foreign_key: "epobject_id"

    # Return all dates for which there are speeches on that day in the given house
    def self.find_all_dates_for_house(house)
      select("hdate").where(major: house_to_major(house)).group("hdate").map(&:hdate)
    end

    def self.house_to_major(house)
      case house
      when "reps"
        1
      when "senate"
        101
      else
        throw "Unexpected value for house: #{house}"
      end
    end

    def self.most_recent_in_house(house)
      where(major: house_to_major(house)).order("hdate DESC, htime DESC").first
    end

    def self.most_recent
      order("hdate DESC, htime DESC").first
    end

    def self.find_all_sections_by_date_and_house(date, house)
      where(major: house_to_major(house), hdate: date, htype: 10)
    end

    def self.last_modified
      Hansard.most_recent.last_modified
    end

    def house
      case major
      when 1
        "reps"
      when 101
        "senate"
      else
        throw "Unexpected value of major: #{major}"
      end
    end

    def section?
      htype == 10
    end

    def subsection?
      htype == 11
    end

    def speech?
      htype == 12
    end

    def procedural?
      htype == 13
    end

    # Takes the modification times of any comments on a speech into account
    def last_modified_including_comments
      if speech?
        (comments.map(&:last_modified) << last_modified).compact.max
      else
        speeches.map(&:last_modified_including_comments).compact.max
      end
    end

    # The last time this was modified. Takes into account all subsections and speeches under this
    # if this is a section or subsection.
    def last_modified
      if speech?
        modified
      else
        speeches.map(&:last_modified).compact.max
      end
    end

    # Returns all the hansard objects which are contained by this Hansard object
    # For example, if this is a section, it returns all the subsections
    def speeches
      if section?
        Hansard.where(section_id: epobject_id, htype: 11)
      elsif subsection?
        Hansard.where(subsection_id: epobject_id)
      elsif speech? || procedural?
        []
      else
        throw "Unknown hansard type (htype: #{htype})"
      end
    end

    def numeric_id
      if gid =~ %r{^uk.org.publicwhip/(lords|debate)/(.*)$}
        $LAST_MATCH_INFO[2]
      else
        throw "Unexpected form of gid #{gid}"
      end
    end

    # TODO: There seems to be an asymmetry between the reps and senate in their handling of the two different kinds of url below
    # Must investigate this

    # Returns the unique url for this bit of the Hansard
    # Again, this should not really be in the model
    def url
      "/#{house == 'reps' ? 'debate' : 'senate'}/?id=#{numeric_id}"
    end

    def self.url_for_date(hdate, house)
      "/#{house == 'reps' ? 'debates' : 'senate'}/?d=#{hdate}"
    end
  end
end

require 'name'

# A collection of members
class Members
  attr_reader :members
  
  def initialize(members)
    @members = members
  end
  
  def Members.load(filename)
    doc = Hpricot(open("pwdata/members/all-members.xml"))
    Members.new(doc.search('member').map{|m| m.attributes})
  end

  def find_member_id_by_fullname(name, date)
    names = name.split(' ')
    names.delete("Mr")
    names.delete("Mrs")
    names.delete("Ms")
    names.delete("Dr")
    if names.size == 2
      firstname = names[0]
      lastname = names[1]
    elsif names.size == 1
      firstname = ""
      lastname = names[0]
    else
      throw "Can't parse the name #{name}"
    end
    find_member_id_by_name(firstname, lastname, date)
  end
  
  private
  
  def find_members_by_lastname(lastname, date)
    @members.find_all do |m|
      fromdate = Date.parse(m["fromdate"])
      todate = Date.parse(m["todate"])
      date >= fromdate && date <= todate && m["lastname"].downcase == lastname.downcase
    end
  end

  # If firstname is empty will just check by lastname
  def find_members_by_name(firstname, lastname, date)
    # First checking if there is an unambiguous match by lastname which allows
    # an amount of variation in first name: ie Tony vs Anthony
    matches = find_members_by_lastname(lastname, date)
    if firstname != "" && matches.size > 1
      matches = @members.find_all do |m|
        fromdate = Date.parse(m["fromdate"])
        todate = Date.parse(m["todate"])
        date >= fromdate && date <= todate && m["firstname"].downcase == firstname.downcase && m["lastname"].downcase == lastname.downcase
      end
    end
    matches
  end

  def find_member_id_by_name(firstname, lastname, date)
    matches = find_members_by_name(firstname, lastname, date)
    throw "More than one match for member based on first name (#{firstname}) and last name #{lastname}" if matches.size > 1
    throw "No match for member found" if matches.size == 0
    matches[0]["id"]
  end
end

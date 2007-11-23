# Handle all our silly name parsing needs
class Name
  attr_accessor :first, :last
  
  def initialize(first, last)
    @first = first.capitalize
    @last = last.capitalize
  end
  
  def Name.last_title_first(text)
    names = text.delete(',').split(" ")
    throw "Unexpected number of names" if names.size != 2
    Name.new(names[1], names[0])
  end
end

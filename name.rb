# Handle all our silly name parsing needs
class Name
  attr_accessor :first, :last
  
  def initialize(params)
    @first = params[:first].capitalize if params[:first]
    @last = params[:last].capitalize if params[:last]
    throw "Invalid keys" unless (params.keys - [:first, :last]).empty?
  end
  
  def Name.last_title_first(text)
    names = text.delete(',').split(" ")
    throw "Unexpected number of names" if names.size != 2
    Name.new(:last => names[0], :first => names[1])
  end
  
  def ==(name)
    @first == name.first && @last == name.last
  end
end

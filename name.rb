# Handle all our silly name parsing needs
class Name
  attr_reader :first, :middle, :last
  
  def initialize(params)
    @first = params[:first].capitalize if params[:first]
    @middle = params[:middle].map{|n| n.capitalize} if params[:middle]
    @last = params[:last].capitalize if params[:last]
    throw "Invalid keys" unless (params.keys - [:first, :middle, :last]).empty?
  end
  
  def Name.last_title_first(text)
    names = text.delete(',').split(" ")
    throw "Too few names" if names.size < 2
    Name.new(:last => names[0], :first => names[1], :middle => names[2..-1])
  end
  
  def ==(name)
    @first == name.first && @last == name.last
  end
end

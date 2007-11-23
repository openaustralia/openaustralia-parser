# Handle all our silly name parsing needs
class Name
  attr_reader :title, :first, :middle, :last
  
  def initialize(params)
    @title = params[:title] || ""
    @first = (params[:first].capitalize if params[:first]) || ""
    @middle = (Name.capitalize_each_word(params[:middle]) if params[:middle]) || ""
    @last = (params[:last].capitalize if params[:last]) || ""
    throw "Invalid keys" unless (params.keys - [:title, :first, :middle, :last]).empty?
  end
  
  def Name.capitalize_each_word(text)
    text.split(' ').map{|t| t.capitalize}.join(' ')
  end
  
  def Name.last_title_first(text)
    names = text.delete(',').split(" ")
    throw "Too few names" if names.size < 2
    if names.size >= 4 && names[1] == "the" && names[2] == "Hon."
      Name.new(:title => "the Hon.", :last => names[0], :first => names[3], :middle => names[4..-1].join(' '))
    else
      Name.new(:last => names[0], :first => names[1], :middle => names[2..-1].join(' '))
    end
  end
  
  def ==(name)
    @title == name.title && @first == name.first && @middle == name.middle && @last == name.last
  end
end

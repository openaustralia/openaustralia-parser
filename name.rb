class String
  def capitalize_each_word
    split(' ').map{|t| t.capitalize}.join(' ')
  end
  
  def surrounded_by_brackets?
    self[0..0] == '(' && self[-1..-1] == ')'
  end
end

# Handle all our silly name parsing needs
class Name
  attr_reader :title, :first, :nick, :middle, :last
  
  def initialize(params)
    @title = params[:title] || ""
    @first = (params[:first].capitalize if params[:first]) || ""
    @nick = (params[:nick].capitalize if params[:nick]) || ""
    @middle = (params[:middle].capitalize_each_word if params[:middle]) || ""
    @last = (params[:last].capitalize if params[:last]) || ""
    throw "Invalid keys" unless (params.keys - [:title, :first, :nick, :middle, :last]).empty?
  end
  
  def Name.last_title_first(text)
    names = text.delete(',').split(" ")
    last = names.shift
    if names.size >= 3 && names[0] == "the" && names[1] == "Hon."
      title = "the Hon."
      names.shift
      names.shift
    end
    first = names.shift
    throw "Too few names" if first.nil?
    # There could be a nickname after the first name in brackets
    if names.size >= 1 && names[0].surrounded_by_brackets?
      nick = names.shift[1..-2]
    end
    Name.new(:title => title, :last => last, :first => first, :nick => nick, :middle => names[0..-1].join(' '))
  end
  
  def ==(name)
    @title == name.title && @first == name.first && @nick == name.nick && @middle == name.middle && @last == name.last
  end
end

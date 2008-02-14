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
    if params[:last]
      @last = params[:last].capitalize
      # Irish and Scottish exception to capitalisation rule
      if @last[0..1] == "O'" || @last[0..1] == "Mc"
        @last = @last[0..1] + @last[2..-1].capitalize
      end
    else
      @last = ""
    end
    throw "Invalid keys" unless (params.keys - [:title, :first, :nick, :middle, :last]).empty?
  end
  
  def Name.last_title_first(text)
    names = text.delete(',').split(' ')
    last = names.shift
    titles = Array.new
    while title = Name.title(names)
      titles << title
    end
    title = titles.join(' ')
    first = names.shift
    throw "Too few names" if first.nil?
    # There could be a nickname after the first name in brackets
    if names.size >= 1 && names[0].surrounded_by_brackets?
      nick = names.shift[1..-2]
    end
    Name.new(:title => title, :last => last, :first => first, :nick => nick, :middle => names[0..-1].join(' '))
  end
  
  def Name.title_first_last(text)
    names = text.delete(',').split(' ')
    titles = Array.new
    while title = Name.title(names)
      titles << title
    end
    title = titles.join(' ')
    throw "Too few names" if names.empty?
    if names.size == 1
      last = names[0]
    else
      first = names[0]
      last = names[-1]
      middle = names[1..-2].join(' ')
    end
    Name.new(:title => title, :last => last, :first => first, :middle => middle)
  end
  
  def informal_name
    throw "No last name" if @last == ""
    if @nick != ""
      "#{@nick} #{@last}"
    else
      throw "No first name" if @first == ""
      "#{@first} #{@last}"
    end
  end
  
  def full_name
    t = ""
    t = t + "#{title} " unless title == ""
    t = t + "#{first} "
    t = t + "(#{nick}) " unless nick == ""
    t = t + "#{middle} " unless middle == ""
    t = t + "#{last}"
    t
  end
  
  def ==(name)
    @title == name.title && @first == name.first && @nick == name.nick && @middle == name.middle && @last == name.last
  end
  
  private
  
  # Extract a title at the beginning of the list of names if available and shift
  def Name.title(names)
    if names.size >= 2 && names[0] == "the" && names[1] == "Hon."
      names.shift
      names.shift
      "the Hon."
    elsif names.size >= 1 && names[0] == "Hon."
        names.shift
        "Hon."
    elsif names.size >= 1
      title = names[0]
      if title == "Dr" || title == "Mr" || title == "Mrs" || title == "Ms"
        names.shift
        title
      end
    end
  end
end

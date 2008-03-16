class String
  def surrounded_by_brackets?
    self[0..0] == '(' && self[-1..-1] == ')'
  end
end

# Handle all our silly name parsing needs
class Name
  attr_reader :title, :first, :first_initial, :nick, :middle, :middle_initials, :last, :post_title
  
  def initialize(params)
    @title = params[:title] || ""
    @first = (Name.capitalize_name(params[:first]) if params[:first]) || ""
    @nick = (Name.capitalize_name(params[:nick]) if params[:nick]) || ""
    @middle = (Name.capitalize_each_name(params[:middle]) if params[:middle]) || ""
    @post_title = (params[:post_title].upcase if params[:post_title]) || ""
    @last = (Name.capitalize_each_name(params[:last]) if params[:last]) || ""
    if params[:first_initial]
      @first_initial = params[:first_initial].upcase
      if has_first? && first_initial_from_name != @first_initial
        throw "Given first initial #{@first_initial} does not match given first name"
      end
    else
      @first_initial = first_initial_from_name
    end
    if params[:middle_initials]
      @middle_initials = params[:middle_initials].upcase
      if has_middle? && middle_initials_from_name != @middle_initials
        throw "Given middle initials #{@middle_initials} does not match given middle names"
      end      
    else
      @middle_initials = middle_initials_from_name      
    end
    invalid_keys = params.keys - [:title, :first, :first_initial, :nick, :middle, :middle_initials, :last, :post_title]
    throw "Invalid keys #{invalid_keys} used" unless invalid_keys.empty?
  end
  
  # Initial purely obtained from the first name
  def first_initial_from_name
    if has_first?
      first[0..0]
    else
      ""
    end
  end
  
  def middle_initials_from_name
    if has_middle?
      middle.split(' ').map{|n| n[0..0]}.join
    else
      ""
    end
  end
  
  def Name.last_title_first(text)
    names = text.delete(',').split(' ')
    # Check for a name in brackets which we take as the nickname
    nickname_text = names.find{|n| n.surrounded_by_brackets?}
    if nickname_text
      nick = nickname_text[1..-2]
      names.delete(nickname_text)
    end
    # Hack to deal with a specific person who has two last names that aren't hyphenated
    if names.size >= 2 && names[0].downcase == "stott" && names[1].downcase == "despoja"
      last = names[0..1].join(' ')
      names.shift
      names.shift
    else
      last = names.shift
    end
    title = Name.extract_title_at_start(names)
    first = names.shift
    throw "Too few names" if first.nil?
    post_titles = []
    while post_title = Name.post_title(names)
      post_titles.unshift(post_title)
    end
    post_title = post_titles.join(' ')
    middle = names[0..-1].join(' ')
    Name.new(:title => title, :last => last, :first => first, :nick => nick, :middle => middle, :post_title => post_title)
  end
  
  # Parse name in the form: "Hardgrave, GD"
  def Name.last_title_initials(text)
    names = text.delete(',').split(' ')
    last = names.shift
    title = Name.extract_title_at_start(names)
    initials = names.shift
    first_initial = initials[0..0] if initials.size > 0
    middle_initials = initials[1..-1] if initials.size > 1
    Name.new(:last => last, :title => title,
      :first_initial => first_initial, :middle_initials => middle_initials)
  end
  
  # Extract a post title from the end if one is available
  def Name.post_title(names)
    if names.last == "AM" || names.last == "SC" || names.last == "AO" ||
      names.last == "MBE" || names.last == "QC" || names.last == "OBE" ||
      names.last == "KSJ" || names.last == "JP"
      names.pop
    end
  end
  
  def Name.title_first_last(text)
    names = text.delete(',').split(' ')
    title = Name.extract_title_at_start(names)
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
    throw "No last name" unless has_last?
    if @nick != ""
      "#{@nick} #{@last}"
    else
      if has_first?
        "#{@first} #{@last}"
      else
        "#{first_initial}#{middle_initials} #{@last}"
      end
    end
  end
  
  def full_name
    t = ""
    t = t + "#{title} " if has_title?
    t = t + "#{first} " if has_first?
    t = t + "(#{nick}) " if has_nick?
    t = t + "#{middle} " if has_middle?
    t = t + "#{last}"
    t = t + ", #{post_title}" if has_post_title?
    t
  end
  
  def has_title?
    @title != ""
  end
  
  def has_first?
    @first != ""
  end
  
  def has_first_initial?
    @first_initial != ""
  end
  
  def has_nick?
    @nick != ""
  end
  
  def has_middle?
    @middle != ""
  end
  
  def has_middle_initials?
    @middle_initials != ""
  end
  
  def has_last?
    @last != ""
  end
  
  def has_post_title?
    @post_title != ""
  end
  
  # Names don't have to be identical to match but rather the parts of the name
  # that exist in both names have to match
  def matches_simply?(name)
    # True if there is overlap between the names
    overlap = (has_title? && name.has_title?) ||
      (has_first_initial?   && name.has_first_initial?) ||
      (has_middle_initials? && name.has_middle_initials?) ||
      (has_first?           && name.has_first?) ||
      (has_nick?            && name.has_nick?) ||
      (has_middle?          && name.has_middle?) ||
      (has_last?            && name.has_last?) ||
      (has_post_title?      && name.has_post_title?)
      
    overlap &&
      (!has_title?           || !name.has_title?           || @title      == name.title) &&
      (!has_first_initial?   || !name.has_first_initial?   || first_initial == name.first_initial) &&
      (!has_middle_initials? || !name.has_middle_initials? || middle_initials == name.middle_initials) &&
      (!has_first?           || !name.has_first?           || @first      == name.first) &&
      (!has_nick?            || !name.has_nick?            || @nick       == name.nick) &&
      (!has_middle?          || !name.has_middle?          || @middle     == name.middle) &&
      (!has_last?            || !name.has_last?            || @last       == name.last) &&
      (!has_post_title?      || !name.has_post_title?      || @post_title == name.post_title)
  end
  
  def matches?(name)
    # Special handling for nicknames
    if (has_first? && name.has_first? && !has_nick? && name.has_nick?)
      return name.matches?(self)
    elsif (has_first? && name.has_first? && has_nick? && !name.has_nick?)
      swapped_first_and_nick = Name.new(:title => name.title, :nick => name.first, :middle => name.middle,
        :last => name.last, :post_title => name.post_title)
      matches_simply?(name) || matches_simply?(swapped_first_and_nick)
    else
      matches_simply?(name)
    end
  end
  
  def ==(name)
    @title == name.title && @first == name.first && @first_initial == name.first_initial && @nick == name.nick &&
      @middle == name.middle && @middle_initials == name.middle_initials && @last == name.last && @post_title == name.post_title
  end
  
  private
  
  def Name.extract_title_at_start(names)
    titles = Array.new
    while title = Name.title(names)
      titles << title
    end
    titles.join(' ')
  end
  
  # Extract a title at the beginning of the list of names if available and shift
  def Name.title(names)
    if names.size >= 3 && names[0] == "the" && names[1] == "Rt" && names[2] == "Hon."
      names.shift
      names.shift
      names.shift
      "the Rt Hon."
    elsif names.size >= 2 && names[0] == "the" && names[1] == "Hon."
      names.shift
      names.shift
      "the Hon."
    elsif names.size >= 1 && names[0] == "Hon."
        names.shift
        "Hon."
    elsif names.size >= 1
      title = names[0]
      if title == "Dr" || title == "Mr" || title == "Mrs" || title == "Ms" || title == "Miss" || title == "Senator"
        names.shift
        title
      end
    end
  end
  
  # Capitalise a name using special rules
  def Name.capitalize_name(name)
    # Simple capitlisation
    name = name.capitalize
    # Replace a unicode character
    name = name.capitalize.gsub("\342\200\231", "'")
    # Exceptions to capitalisation rule
    if name[0..1] == "O'" || name[0..1] == "Mc" || name[0..1] == "D'"
      name = name[0..1] + name[2..-1].capitalize
    end
    name
  end

  def Name.capitalize_each_name(name)
    name.split(' ').map{|t| Name.capitalize_name(t)}.join(' ')
  end
end

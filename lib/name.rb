# Handle all our silly name parsing needs
class Name
  attr_reader :title, :first, :middle, :initials, :last, :post_title
  
  def initialize(params)
    @title = params[:title] || ""
    @first = (Name.capitalize_name(params[:first]) if params[:first]) || ""
    @middle = (Name.capitalize_each_name(params[:middle]) if params[:middle]) || ""
    @initials = (params[:initials].upcase if params[:initials]) || ""
    @post_title = (params[:post_title].upcase if params[:post_title]) || ""
    @last = (Name.capitalize_each_name(params[:last]) if params[:last]) || ""
    invalid_keys = params.keys - [:title, :first, :middle, :initials, :last, :post_title]
    throw "Invalid keys #{invalid_keys} used" unless invalid_keys.empty?
  end
  
  def Name.remove_text_in_brackets(text)
    open = text.index('(')
    if open
      close = text.index(')', open)
      if close
        text = text[0..open-1] + text[close+1..-1]
      end
    end

    # Remove extra spaces
    text.squeeze(' ')
  end
  
  def Name.last_title_first(text)
    # Do the following before the split so we can handle things like "(foo bar)"
    text = remove_text_in_brackets(text)
    names = text.delete(',').split(' ')
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
    post_title = extract_post_title_at_end(names)
    middle = names[0..-1].join(' ')
    Name.new(:title => title, :last => last, :first => first, :middle => middle, :post_title => post_title)
  end
  
  # Extract a post title from the end if one is available
  def Name.post_title(names)
    if names.last == "AM" || names.last == "SC" || names.last == "AO" ||
      names.last == "MBE" || names.last == "QC" || names.last == "OBE" ||
      names.last == "KSJ" || names.last == "JP" || names.last == "MP"
      names.pop
    end
  end
  
  def Name.title_first_last(text)
    names = text.delete(',').split(' ')
    title = Name.extract_title_at_start(names)
    throw "Too few names in '#{text}'" if names.empty?
    if names.size == 1
      last = names[0]
    # HACK: Dealing with Stott Despoja as a special case
    elsif names.size == 2 && names[0].downcase == "stott" && names[1].downcase == "despoja"
      last = names[0..1].join(' ')
      names.shift
      names.shift
    else
      # If only one or two letters assume that these are initials
      # HACK: Added specific handling for initials DJC, DGH
      if names[0].size <= 2 || names[0] == "DJC" || names[0] == "DGH"
        initials = names.shift
      else
        first = names.shift
      end
      post_title = extract_post_title_at_end(names)
      # HACK: Another Stott Despoja hack
      if names.size >= 2 && names[-2].downcase == "stott" && names[-1].downcase == "despoja"
        last = names[-2..-1].join(' ')
        names.pop
      else
        last = names[-1]
      end
      names.pop
      middle = names[0..-1].join(' ')
    end
    Name.new(:title => title, :last => last, :first => first, :middle => middle, :initials => initials, :post_title => post_title)
  end
  
  def first_initial
    if has_first_initial?
      @initials[0..0]
    else
      @first[0..0]
    end
  end
  
  def middle_initials
    if has_middle_initials?
      @initials[1..-1]
    else
      @middle.split(' ').map{|n| n[0..0]}.join
    end
  end
  
  def informal_name
    throw "No last name" unless has_last?
    "#{@first} #{@last}"
  end
  
  def full_name
    t = ""
    t = t + "#{title} " if has_title?
    t = t + "#{first} " if has_first?
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
  
  def has_middle?
    @middle != ""
  end
  
  def has_first_initial?
    @initials.size > 0
  end
  
  def has_middle_initials?
    @initials.size > 1
  end
  
  def has_last?
    @last != ""
  end
  
  def has_post_title?
    @post_title != ""
  end
  
  def first_matches?(name)
    if !has_first? || !name.has_first?
      # Check here if one name has initials and no first name and the other has a first name
      if (has_first_initial? && name.has_first?) || (has_first? && name.has_first_initial?)
        first_initial == name.first_initial
      else
        true
      end
    elsif first.size < name.first.size
      name.first_matches?(self)
    else
      first == name.first
    end
  end

  def middle_matches?(name)
    if !has_middle? || !name.has_middle?
      if (has_middle_initials? && name.has_middle?) || (has_middle? && name.has_middle_initials?)
        middle_initials == name.middle_initials
      else
        true
      end
    else
      @middle == name.middle
    end
  end
  
  # Names don't have to be identical to match but rather the parts of the name
  # that exist in both names have to match
  def matches?(name)
    # Both names need to have a last name to match
    return false unless has_last? && name.has_last?
    
    (!has_title?           || !name.has_title?           || @title      == name.title) &&
    first_matches?(name) &&
    middle_matches?(name) &&
    (!has_last?            || !name.has_last?            || @last       == name.last) &&
    (!has_post_title?      || !name.has_post_title?      || @post_title == name.post_title)
  end
  
  def ==(name)
    @title == name.title && @first == name.first &&
      @middle == name.middle && @initials == name.initials && @last == name.last && @post_title == name.post_title
  end
  
  private
  
  def Name.extract_title_at_start(names)
    titles = Array.new
    while title = Name.title(names)
      titles << title
    end
    titles.join(' ')
  end
  
  def Name.extract_post_title_at_end(names)
    post_titles = []
    while post_title = Name.post_title(names)
      post_titles.unshift(post_title)
    end
    post_titles.join(' ')
  end
  
  def Name.matches_hon?(name)
    name.downcase == "hon." || name.downcase == "hon"
  end
  
  # Extract a title at the beginning of the list of names if available and shift
  def Name.title(names)
    if names.size >= 3 && names[0].downcase == "the" && names[1].downcase == "rt" && matches_hon?(names[2])
      names.shift
      names.shift
      names.shift
      "the Rt Hon."
    elsif names.size >= 2 && names[0].downcase == "the" && matches_hon?(names[1])
      names.shift
      names.shift
      "the Hon."
    elsif names.size >= 1 && matches_hon?(names[0])
        names.shift
        "Hon."
    elsif names.size >= 1
      title = names[0]
      if title == "Dr" || title == "Mr" || title == "Mrs" || title == "Ms" || title == "Miss" || title == "Senator" || title == "Lady"
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
    # If name is hyphenated capitalise each side on its own
    name = name.split('-').map{|n| capitalize_name(n)}.join('-') if name.include?('-')
    name
  end

  def Name.capitalize_each_name(name)
    name.split(' ').map{|t| Name.capitalize_name(t)}.join(' ')
  end
end

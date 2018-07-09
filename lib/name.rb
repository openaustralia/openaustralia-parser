require 'environment'
require 'enumerator'
require 'active_support/all'

$KCODE = 'u'

# Handle all our silly name parsing needs
class Name
  attr_reader :title, :first, :middle, :initials, :last, :post_title
  
  def initialize(params)
    # First normalize the unicode.
    params.map {|key, value| [key, (value.mb_chars.normalize if value)]}
    
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
    # First normalize the unicode. Using this form of normalize so that non-breaking spaces get turned into 'normal' spaces
    text = text.mb_chars.normalize
    # Do the following before the split so we can handle things like "(foo bar)"
    text = remove_text_in_brackets(text)
    names = text.delete(',').split(' ')
    # Hack to deal with a specific person who has two last names that aren't hyphenated
    if names.size >= 2 && names[0].downcase == "stott" && names[1].downcase == "despoja" ||
       names.size >= 2 && names[0].downcase == "van" && names[1].downcase == "manen" ||
       names.size >= 2 && names[0].downcase == "di" && names[1].downcase == "natale"
      last = names[0..1].join(' ')
      names.shift
      names.shift
    # Check for hyphenated last names
    elsif names[1] == '-'
      last = names.shift(3).join
    else
      last = names.shift
    end
    title = Name.extract_title_at_start(names)
    # Check for hypenated first name
    if names[1] == '-'
      first = names.shift(3).join
    elsif names.size >= 1
      # First name could be in the form of initials. So, check for this
      if initials(names[0])
        # Allow several initials separated by spaces
        initials = ""
        while names.size >= 1 && initials(names[0])
          initials << initials(names.shift)
        end
      else
        first = names.shift
      end
    end
    post_title = extract_post_title_at_end(names)
    middle = names[0..-1].join(' ')
    Name.new(:title => title, :initials => initials, :last => last, :first => first, :middle => middle, :post_title => post_title)
  end
  
  # Extract a post title from the end if one is available
  def Name.post_title(names)
    valid_post_titles = ["AM", "SC", "AO", "MBE", "QC", "OBE", "KSJ", "JP", "MP", "AC", "RFD", "OAM", "MC"]
    names.pop if valid_post_titles.include?(names.last)
  end
  
  # Returns initials if the name could be a set of initials
  def Name.initials(name)
    # If only one or two letters assume that these are initials
    # HACK: Added specific handling for initials DJC, DGH
    if initials_with_fullstops(name)
      initials_with_fullstops(name)
    # Heuristic: If word is all caps we'll assume that these are initials
    # HACK: Unless it's "DAVID", which is how SMITH, DAVID is represented.
    elsif name == "DAVID"
      nil
    # HACK: unless it is "-", which could be part of a hyphenated name in specific case
    elsif (name.upcase == name) && name != "-"
      name
    elsif (name != "Ed" && name != "Jo" && name != "-" && name.size <= 2) || name == "DJC" || name == "DGH"
      name
    end
  end
  
  # Returns true if the name could be a set of initials with full stops in them (e.g. "A.B.")
  def Name.initials_with_fullstops(name)
    # Heuristic: If word has any fullstops in it we'll assume that these are initials
    # This allows a degree of flexibility, such as allowing "A.B.", "A.B..", "A.B.C", etc...
    if name.include?('.')
      name.delete('.')
    end
  end
  
  def Name.title_first_last(text)
    # First normalize the unicode. Using this form of normalize so that non-breaking spaces get turned into 'normal' spaces
    text = text.mb_chars.normalize
    names = text.delete(',').split(' ')
    title = Name.extract_title_at_start(names)
    if names.size == 1
      last = names[0]
    # HACK: Dealing with Stott Despoja as a special case
    elsif names.size == 2 && names[0].downcase == "stott" && names[1].downcase == "despoja" ||
          names.size == 2 && names[0].downcase == "van" && names[1].downcase == "manen" ||
          names.size >= 2 && names[0].downcase == "di" && names[1].downcase == "natale"
      last = names[0..1].join(' ')
      names.shift
      names.shift
    elsif names.size >= 2
      if initials(names[0])
        initials = initials(names.shift)
      else
        first = names.shift
      end
      post_title = extract_post_title_at_end(names)
      # HACK: Another Stott Despoja hack
      if names.size >= 2 && names[-2].downcase == "stott" && names[-1].downcase == "despoja" ||
         names.size >= 2 && names[-2].downcase == "van" && names[-1].downcase == "manen" ||
         names.size >= 2 && names[0].downcase == "di" && names[1].downcase == "natale"
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

  def real_initials
    # If only one or two letters assume that these are initials
    # HACK: Added specific handling for initials DJC, DGH
    if not @initials.nil? and @initials.length > 0
      @initials
    elsif not @first.nil?
      if @first.upcase == @first
        @first
      elsif (@first != "Ed" && @first.size <= 2) || @first == "DJC" || @first == "DGH"
        @first
      else
        p_initials = first_initial
        if not @middle.nil?
          p_initials = "#{p_initials}#{@middle.split(' ').map{|n| n[0..0]}.join}"
        end
        p_initials
      end
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
        middle_initials == name.middle_initials[0..middle_initials.length-1]
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
      if title == "Dr" || title == "Mr" || title == "Mrs" || title == "Ms" || title == "Miss" || title == "Senator" || title == "Sen" || title == "Lady"
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
    # TODO: Fix 'activesupport' gem so that multibyte chars properly pass through include?
    # Cast to normal string for include? necessary because of bug in activesupport multibyte chars
    name = name.split('-').map{|n| capitalize_name(n)}.join('-') if name.to_s.include?('-')
    name
  end

  def Name.capitalize_each_name(name)
    name.split(' ').map{|t| Name.capitalize_name(t)}.join(' ')
  end
end

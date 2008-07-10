# Very dumb class for representing whether something is in the House of Representatives or the Senate
class House
  attr_reader :name
  
  REPRESENTATIVES = "representatives"
  SENATE = "senate"
  
  def House.senate
    House.new(SENATE)
  end
  
  def House.representatives
    House.new(REPRESENTATIVES)
  end
  
  def initialize(name)
    throw "Name of house must '#{REPRESENTATIVES}' or '#{SENATE}'" unless name == REPRESENTATIVES || name == SENATE
    @name = name    
  end
  
  def representatives?
    name == REPRESENTATIVES
  end
  
  def senate?
    name == SENATE
  end
end

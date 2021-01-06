# frozen_string_literal: true

# Very dumb class for representing whether something is in the House of Representatives or the Senate
class House
  attr_reader :name

  REPRESENTATIVES = "representatives"
  SENATE = "senate"

  def self.senate
    House.new(SENATE)
  end

  def self.representatives
    House.new(REPRESENTATIVES)
  end

  def initialize(name)
    raise "Name of house must '#{REPRESENTATIVES}' or '#{SENATE}'" unless name == REPRESENTATIVES || name == SENATE

    @name = name
  end

  def representatives?
    name == REPRESENTATIVES
  end

  def senate?
    name == SENATE
  end

  def to_s
    name
  end

  def ==(other)
    name == other.name
  end
end

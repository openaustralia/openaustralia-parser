$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'test/unit'
require 'name'

class TestName < Test::Unit::TestCase
  def setup
    @matthew = Name.new(:first => "Matthew", :middle => "Noah", :last => "Landauer")
    @joanna_gash = Name.new(:first => "Joanna", :last => "Gash")
  end
  
  def test_new
    assert_equal("Matthew", @matthew.first)
    assert_equal("Noah", @matthew.middle)
    assert_equal("Landauer", @matthew.last)
  end
  
  def test_new_wrong_parameters
    assert_raise(NameError){ Name.new(:first => "foo", :blah => "dibble") }
  end
  
  def test_equals
    assert_equal(@matthew, Name.new(:last => "Landauer", :middle => "Noah", :first => "Matthew"))
    assert_not_equal(@matthew, Name.new(:last => "Landauer"))
  end
  
  def test_simple_parse
    assert_equal(@joanna_gash, Name.last_title_first("Gash Joanna"))
  end
  
  def test_capitals
    assert_equal(@joanna_gash, Name.last_title_first("GASH joanna"))
  end
  
  def test_comma
    assert_equal(@joanna_gash, Name.last_title_first("Gash, Joanna"))
  end
  
  def test_middle_name
    assert_equal(Name.new(:last => "Albanese", :first => "Anthony", :middle => "Norman"),
      Name.last_title_first("Albanese Anthony Norman"))
  end
  
  def test_two_middle_names
    assert_equal(Name.new(:last => "Albanese", :first => "Anthony", :middle => "Norman peter"),
      Name.last_title_first("Albanese Anthony Norman Peter"))
  end
  
  def test_the_hon
    assert_equal(Name.new(:last => "Baird", :title => "the Hon.", :first => "Bruce", :middle => "George"),
      Name.last_title_first("Baird the Hon. Bruce George"))
  end
  
  def test_nickname
    assert_equal(Name.new(:last => "Abbott", :title => "the Hon.", :first => "Anthony", :nick => "Tony", :middle => "John"),
      Name.last_title_first("ABBOTT, the Hon. Anthony (Tony) John"))
  end
  
  def test_dr
    assert_equal(Name.new(:last => "Emerson", :title => "Dr", :first => "Craig", :middle => "Anthony"),
      Name.last_title_first("EMERSON, Dr Craig Anthony"))
  end
  
  def test_informal_name
    assert_equal("Matthew Landauer", Name.new(:first => "Matthew", :last => "Landauer", :title => "Dr").informal_name)
    assert_equal("Matt Landauer", Name.new(:first => "Matthew", :nick => "Matt", :last => "Landauer", :title => "Dr").informal_name)
  end
  
  def test_capitals_irish_name
    assert_equal("O'Connor", Name.new(:last => "o'connor").last)
  end
  
  def test_capitals_scottish_name
    assert_equal("McMullan", Name.new(:last => "mcmullan").last)
  end
  
  def test_dath
    assert_equal("D'Ath", Name.new(:last => "d’ath").last)
  end
  
  def test_title_first_last
    assert_equal(Name.new(:title => "Dr", :first => "John", :last => "Smith"), Name.title_first_last("Dr John Smith"))
    assert_equal(Name.new(:title => "Dr", :last => "Smith"), Name.title_first_last("Dr Smith"))
    assert_equal(Name.new(:title => "Mr", :last => "Smith"), Name.title_first_last("Mr Smith"))
    assert_equal(Name.new(:title => "Mrs", :last => "Smith"), Name.title_first_last("Mrs Smith"))
    assert_equal(Name.new(:title => "Ms", :first => "Julie", :last => "Smith"), Name.title_first_last("Ms Julie Smith"))
    assert_equal(Name.new(:title => "Ms", :first => "Julie", :middle => "Sarah Marie", :last => "Smith"),
      Name.title_first_last("Ms Julie Sarah Marie Smith"))
  end
  
  def test_john_debus
    # He has a title of "Hon." rather than "the Hon."
    name = Name.last_title_first("DEBUS, Hon. Robert (Bob) John")
    assert_equal("Debus", name.last)
    assert_equal("Hon.", name.title)
    assert_equal("Robert", name.first)
    assert_equal("Bob", name.nick)
    assert_equal("John", name.middle)
  end
  
  # Deal with weirdo titles at the end
  def test_post_title
    name = Name.last_title_first("COMBET, the Hon. Gregory (Greg) Ivan, AM")
    assert_equal("Combet", name.last)
    assert_equal("the Hon.", name.title)
    assert_equal("Gregory", name.first)
    assert_equal("Greg", name.nick)
    assert_equal("Ivan", name.middle)
    assert_equal("AM", name.post_title)
  end
  
  # Class for simple (naive) way of comparing two names. Only compares parts of the name
  # that exist in both names
  def test_matches
    dr_john_smith = Name.new(:title => "Dr", :first => "John", :last => "Smith")
    john_smith = Name.new(:first => "John", :last => "Smith")
    peter_smith = Name.new(:first => "Peter", :last => "Smith")
    smith = Name.new(:last => "Smith")
    dr_john = Name.new(:title => "Dr", :first => "John")
    assert(dr_john_smith.matches?(dr_john_smith))
    assert(!dr_john_smith.matches?(peter_smith))
    # When there is no overlap between the names they should not match
    assert(!smith.matches?(dr_john))
  end
end
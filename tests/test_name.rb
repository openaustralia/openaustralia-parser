$:.unshift "#{File.dirname(__FILE__)}/.."

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
  
  def test_title_first_last
    assert_equal(Name.new(:title => "Dr", :first => "John", :last => "Smith"), Name.title_first_last("Dr John Smith"))
    assert_equal(Name.new(:title => "Dr", :last => "Smith"), Name.title_first_last("Dr Smith"))
    assert_equal(Name.new(:title => "Mr", :last => "Smith"), Name.title_first_last("Mr Smith"))
    assert_equal(Name.new(:title => "Mrs", :last => "Smith"), Name.title_first_last("Mrs Smith"))
    assert_equal(Name.new(:title => "Ms", :first => "Julie", :last => "Smith"), Name.title_first_last("Ms Julie Smith"))
    assert_equal(Name.new(:title => "Ms", :first => "Julie", :middle => "Sarah Marie", :last => "Smith"),
      Name.title_first_last("Ms Julie Sarah Marie Smith"))
  end
end
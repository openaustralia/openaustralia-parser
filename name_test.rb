require 'test/unit'
require 'name'

class NameTest < Test::Unit::TestCase
  def setup
    @matthew = Name.new(:first => "Matthew", :last => "Landauer")
    @joanna_gash = Name.new(:first => "Joanna", :last => "Gash")
  end
  
  def test_new
    assert_equal("Matthew", @matthew.first)
    assert_equal("Landauer", @matthew.last)
  end
  
  def test_new_wrong_parameters
    assert_raise(NameError){ Name.new(:first => "foo", :blah => "dibble") }
  end
  
  def test_equals
    assert_equal(@matthew, Name.new(:last => "Landauer", :first => "Matthew"))
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
end
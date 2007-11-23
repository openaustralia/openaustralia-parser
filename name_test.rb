require 'test/unit'
require 'name'

class NameTest < Test::Unit::TestCase
  def test_simple
    name = Name.last_title_first("Gash Joanna")
    assert_equal("Gash", name.last)
    assert_equal("Joanna", name.first)
  end
  
  def test_capitals
    name = Name.last_title_first("GASH joanna")
    assert_equal("Gash", name.last)
    assert_equal("Joanna", name.first)
  end
  
  def test_comma
    name = Name.last_title_first("Gash, Joanna")
    assert_equal("Gash", name.last)
    assert_equal("Joanna", name.first)
  end
end
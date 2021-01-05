$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'test/unit'
require 'date_with_future'

class TestDateWithFuture < Test::Unit::TestCase
  def test_normal_date
    assert_equal("2000-01-02", DateWithFuture.new(2000, 1, 2).to_s)
  end

  def test_future
    assert_equal(DateWithFuture.new(9999, 12, 31), DateWithFuture.future)
  end
end

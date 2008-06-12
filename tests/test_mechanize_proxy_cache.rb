$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'test/unit'
require 'mechanize_proxy'

class TestMechanizeProxyCache < Test::Unit::TestCase
  def setup
    @cache = MechanizeProxyCache.new
    @cache.cache_subdirectory = "test"
  end
  
  def test_quoting_on_attributes
    page = PageProxy.new(Hpricot('<a href="http://www.blah.com?foo&amp;blah">Some Text</a>'), "http://test.com/test1.html") 
    assert_equal('http://www.blah.com?foo&blah', page.parser.search('a').first.get_attribute('href'))
    @cache.write_cache(page)
    
    # Reload from cache
    page2 = @cache.read_cache(page.uri)
    assert_equal('http://www.blah.com?foo&blah', page2.parser.search('a').first.get_attribute('href'))
  end
end
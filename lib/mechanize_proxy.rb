# Very stripped down proxy for WWW::Mechanize
#
# Stores cached html files in directory "html_cache_path" in configuration.yml

require 'environment'
require 'mechanize'
require 'configuration'

class MechanizeProxyCache
  # By setting cache_subdirectory can put cached files under a subdirectory in the html_cache_path
  attr_accessor :cache_subdirectory

  def initialize
    @conf = Configuration.new
  end
end

class MechanizeProxy
  def initialize
    @agent = WWW::Mechanize.new
    # For the time being force the use of Hpricot rather than nokogiri
    WWW::Mechanize.html_parser = Hpricot
    @cache = MechanizeProxyCache.new
  end

  def cache_subdirectory
    @cache.cache_subdirectory
  end

  def cache_subdirectory=(path)
    @cache.cache_subdirectory = path
  end

  def user_agent_alias=(a)
    @agent.user_agent_alias = a
  end

  def get(url)
    @agent.get(url)
  end

  def click(link)
    @agent.click(link)
  end

  def transact
    @agent.transact { yield }
  end
end

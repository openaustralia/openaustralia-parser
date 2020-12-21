# Very stripped down proxy for WWW::Mechanize

require 'mechanize'
require 'configuration'

class MechanizeProxy
  def initialize
    @agent = WWW::Mechanize.new
    # For the time being force the use of Hpricot rather than nokogiri
    WWW::Mechanize.html_parser = Hpricot
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

require 'hansard_page'

class HansardDay
  def initialize(page, logger = nil)
    @page, @logger = page, logger
  end
  
  def house
    case @page.at('chamber').inner_html
      when "SENATE" then House.senate
      when "REPS" then House.representatives
      else throw "Unexpected value for contents of <chamber> tag"
    end
  end
  
  def date
    Date.parse(@page.at('date').inner_html)
  end
  
  def permanent_url
    house_letter = house.representatives? ? "r" : "s"
    "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:chamber/hansard#{house_letter}/#{date}/0000"
  end
  
  def in_proof?
    proof = @page.at('proof').inner_html
    logger.error "Unexpected value '#{proof}' inside tag <proof>" unless proof == "1" || proof == "0"
    proof == "1"
  end

  def pages
    # Step through the top-level debates
    p = []
    @page.search('debate').each do |e|
      title = e.at('title').inner_html
      # If there are no sub-debates then make this a page on its own
      if e.search('/(subdebate.1)').empty?
        p << HansardPage.new(e, title, nil, self)
      else
        e.search('/(subdebate.1)').each do |s1|
          subtitle1 = s1.at('title').inner_html
          if s1.search('/(subdebate.2)').empty?
            p << HansardPage.new(s1, title, subtitle1, self)
          else
            s1.search('/(subdebate.2)').each do |s2|
              subtitle2 = s2.at('title').inner_html
              p << HansardPage.new(s2, title, subtitle1 + "; " + subtitle2, self)
            end
          end
        end
      end
    end
    p
  end  
end
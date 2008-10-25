require 'hansard_page'

module Hpricot
  module Traverse
    # Iterate over the children that aren't text nodes
    def each_child_node
      children.each do |c|
        yield c if c.respond_to?(:name)
      end
    end
  end
end

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

  def title_from_debate(e)
    title = e.at('title').inner_html
    cognates = e.search('cognateinfo > title').map{|a| a.inner_html}
    ([title] + cognates).join('; ')
  end
  
  def title_from_subdebate1(e)
    e.at('title').inner_html
  end
  
  def title_from_subdebate2(e)
    subtitle1 = title_from_subdebate1(e.parent)
    subtitle2 = e.at('title').inner_html
    subtitle1 + "; " + subtitle2
  end
  
  def title(debate)
    case debate.name
    when 'debate'
      title_from_debate(debate)
    when 'subdebate.1'
      title_from_debate(debate.parent) + "; " + title_from_subdebate1(debate)
    when 'subdebate.2'
      title_from_debate(debate.parent.parent) + "; " + title_from_subdebate2(debate)
    else
      throw "Unexpected tag #{debate.name}"
    end    
  end
  
  def pages_from_debate(debate)
    title = title(debate)
      
    procedural = false
    debate.each_child_node do |e|
      case e.name
      when 'debateinfo', 'subdebateinfo'
        procedural = false
      when 'speech', 'division', 'question'
        puts "#{e.name} > #{title}"
        procedural = false
      when 'answer'
        # We'll skip answer because they always come in pairs of 'question' and 'answer'
        procedural = false
      when 'motionnospeech', 'para', 'motion', 'interjection', 'quote'
        puts "Procedural text: #{e.name} > #{title}" unless procedural
        procedural = true
      when 'subdebate.1', 'subdebate.2'
        pages_from_debate(e)
        procedural = false
      else
        throw "Unexpected tag #{e.name}"
      end
    end
  end
  
  def pages
    # Step through the top-level debates
    # We're just going to display the titles of the pages so we can match it up to the links in the old parlinfo web system
    puts "Official Hansard"
    @page.at('hansard').each_child_node do |e|
      case e.name
      when 'session.header'
      when 'chamber.xscript', 'maincomm.xscript'
        e.each_child_node do |e|
          case e.name
            when 'business.start', 'adjournment'
              puts e.name
            when 'debate'
              pages_from_debate(e)
            else
              throw "Unexpected tag #{e.name}"
          end
        end
      when 'answers.to.questions'
        e.each_child_node do |e|
          case e.name
          when 'debate'
            pages_from_debate(e)
          else
            throw "Unexpected tag #{e.name}"
          end
        end
      else
        throw "Unexpected tag #{e.name}"
      end
    end
    []
  end  
end
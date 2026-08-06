# frozen_string_literal: true

require "mechanize"

module AphMechanizeAgent
  # We've been kindly given a special user agent to use so that our traffic
  # isn't blocked by the application firewall of aph.gov.au.
  # See https://mail.missiveapp.com/#search/aph.gov.au/conversations/4f0a0161-421e-4d0b-9dd1-49275353acf7/messages/bc27bcd1-2cba-5e63-64d3-a364037629a2
  USER_AGENT = "Mozilla/5.0+AppleWebKit/537.36+(KHTML,+like+Gecko;+compatible;+Amazonbot/0.1;++https://developer.amazon.com/support/amazonbot)+Chrome/119.0.6045.214+Safari/537.36"

  # Returns a Mechanize agent configured with the UA aph.gov.au has asked us to use.
  def self.new_agent
    agent = Mechanize.new
    agent.user_agent = USER_AGENT
    agent
  end
end

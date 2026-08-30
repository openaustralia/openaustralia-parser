# frozen_string_literal: true

require "mechanize"

module AphMechanizeAgent
  # We've been kindly given a special user agent to use so that our traffic
  # isn't blocked by the application firewall of aph.gov.au.
  # See https://mail.missiveapp.com/#search/aph.gov.au/conversations/4f0a0161-421e-4d0b-9dd1-49275353acf7/messages/bc27bcd1-2cba-5e63-64d3-a364037629a2
  USER_AGENT = "Mozilla/5.0+AppleWebKit/537.36+(KHTML,+like+Gecko;+compatible;+Amazonbot/0.1;++https://developer.amazon.com/support/amazonbot)+Chrome/119.0.6045.214+Safari/537.36"

  # HTTP status codes worth backing off and retrying for (rate limiting/transient
  # blocks/gateway hiccups), as opposed to e.g. a 404 which just means there's no
  # Hansard for that day.
  RETRYABLE_RESPONSE_CODES = %w[403 429 502 503 504].freeze

  # Returns a Mechanize agent configured with the UA aph.gov.au has asked us to use.
  def self.new_agent
    agent = Mechanize.new
    agent.user_agent = USER_AGENT
    agent
  end

  # Retries the given block with exponential backoff when aph.gov.au responds with a
  # retryable error (e.g. 403 when we're making requests too quickly). Re-raises once
  # attempts are exhausted, or immediately for any other kind of error.
  def self.with_backoff(attempts: 5, initial_delay: 5)
    delay = initial_delay
    attempt = 1
    begin
      yield
    rescue Mechanize::ResponseCodeError => e
      raise unless RETRYABLE_RESPONSE_CODES.include?(e.response_code) && attempt < attempts

      warn "aph.gov.au returned #{e.response_code}, retrying in #{delay}s (attempt #{attempt}/#{attempts})"
      sleep delay
      attempt += 1
      delay *= 2
      retry
    end
  end
end

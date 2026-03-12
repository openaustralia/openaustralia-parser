# frozen_string_literal: true

require "vcr"
require "webmock/rspec"

VCR.configure do |c|
  c.cassette_library_dir = "spec/cassettes"
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.default_cassette_options = { record: :new_episodes }

  # Never record image requests — WebMock stubs handle those instead.
  # Any URL ending in a common image extension is excluded from VCR.
  c.ignore_request do |request|
    request.uri.match?(/\.(jpg|jpeg|png|gif|webp)(\?.*)?$/i)
  end

  # Don't record API keys in cassettes
  c.filter_sensitive_data("<MORPH_API_KEY>") do
    begin
      require_relative "../lib/configuration"
      Configuration.new.morph_api_key
    rescue StandardError
      "MORPH_API_KEY"
    end
  end

  c.filter_sensitive_data("<TVFY_API_KEY>") do
    begin
      require_relative "../lib/configuration"
      Configuration.new.theyvoteforyou_api_key
    rescue StandardError
      "TVFY_API_KEY"
    end
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.order = :defined

  # Integration tests are slower and require real data files — opt-in only.
  # Run with: bundle exec rspec --tag integration
  # Skip with: bundle exec rspec --tag ~integration  (default CI behaviour)
  config.filter_run_when_matching :focus
end

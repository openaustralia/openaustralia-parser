# frozen_string_literal: true

source "https://rubygems.org"

gem "rake"

# gem "hpricot"
gem "csv"
gem "htmlentities"
gem "mechanize"
gem "nokogiri"

# Version 3 of builder outputs utf8 strings which will make the regression
# tests fail. It would be good to check that the rest of the pipeline
# (on openaustralia.org.au) can handle this change before we upgrade.
gem "builder", "~> 2"
gem "log4r"

# gem "rmagick"

gem "mysql2"
gem "ruby-progressbar"

# For sitemap generation
gem "activerecord", "~> 6.1.0 "

group :development do
  gem "rubocop", require: false
  gem "rubocop-rake"
  gem "rubocop-rspec"
end

group :test do
  gem "rspec"
  gem "test-unit"
  # TODO: rcov doesn't work on ruby > 1.8. Switch to simplecov
  # gem 'rcov', "~> 0.9.10"
end

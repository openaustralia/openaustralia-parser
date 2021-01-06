# frozen_string_literal: true

source "http://rubygems.org"

gem "rake"

gem "hpricot"
gem "htmlentities"
gem "mechanize"

# Version 3 of builder outputs utf8 strings which will make the regression
# tests fail. It would be good to check that the rest of the pipeline
# (on openaustralia.org.au) can handle this change before we upgrade.
gem "builder", "~> 2"
gem "log4r"

gem "rmagick"

gem "mysql2"

group :development do
  gem "rubocop", "~> 1.7", require: false
end

group :test do
  gem "rspec"
  gem "test-unit"
  # TODO: rcov doesn't work on ruby > 1.8. Switch to simplecov
  # gem 'rcov', "~> 0.9.10"
end

# frozen_string_literal: true

source "https://rubygems.org"

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
gem "ruby-progressbar"

# For sitemap generation
gem "activerecord", "~> 7.0.10"

group :development do
  gem "rubocop", "~> 1.7", require: false
  gem "rubocop-rake"
  gem "rubocop-rspec"
end

group :test do
  gem "rspec"
  gem "simplecov"
  gem "simplecov-console"
  gem "timecop"
  gem "vcr"
  gem "webmock"
end

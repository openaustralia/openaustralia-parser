# frozen_string_literal: true

source "https://rubygems.org"

ruby file: ".ruby-version"

gem "activerecord", "~> 8.0.4" # For sitemap generation
gem "builder", "~> 3.0"
gem "csv"
gem "hpricot"
gem "htmlentities"
gem "log4r"
gem "logger"
gem "mechanize"
gem "mysql2"
gem "nokogiri", ">= 1.19.1"
gem "ostruct"
gem "rake"
gem "rmagick"
gem "ruby-progressbar"

group :development do
  gem "rubocop", require: false #  "~> 1.7",
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

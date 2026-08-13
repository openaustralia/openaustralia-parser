# frozen_string_literal: true

source "https://rubygems.org"

ruby file: ".ruby-version"

gem "activerecord", "~> 8.0.4", require: "active_record" # For sitemap generation
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
  gem "bundle-audit", require: false
  gem "rubocop", require: false #  "~> 1.7",
  gem "rubocop-rake"
  gem "rubocop-rspec"
  gem "ruby_audit", require: false
end

group :test do
  gem "rspec"
  gem "simplecov"
  gem "simplecov-console"
  gem "timecop"
  gem "vcr"
  gem "webmock"
end

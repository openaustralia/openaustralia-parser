source "http://rubygems.org"

gem 'rake'

# Mechanize 2 drop support for hpricot which we're still using.
# We should switch to using nokogiri
gem 'mechanize', "~> 1"
gem 'hpricot'
# iconv is required by Mechanize 1
gem 'iconv'
gem 'htmlentities'

# Version 3 of builder outputs utf8 strings which will make the regression
# tests fail. It would be good to check that the rest of the pipeline
# (on openaustralia.org.au) can handle this change before we upgrade.
gem 'builder', "~> 2"
gem 'log4r'

gem 'rmagick'

gem 'mysql2'

group :test do
  gem 'rspec'
  gem 'test-unit'
  # TODO: rcov doesn't work on ruby > 1.8. Switch to simplecov
  # gem 'rcov', "~> 0.9.10"
end

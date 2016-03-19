source "http://rubygems.org"

gem 'rake'
gem 'activesupport'
gem 'i18n' # Required by activesupport
gem 'mechanize', '0.9.2'
# Force using this version of hpricot so Marshal.dump of PageProxy object doesn't fail. Ugh.
gem 'hpricot', "= 0.6.164"
gem 'htmlentities'
gem 'json'

gem 'builder', '2.1.2'
gem 'log4r'

gem 'rmagick'
# Travis was complaining this was missing from the Gemfile. Do we really need it?
gem 'hoe'

group :test do
  gem 'rspec'
  gem 'rcov'
end

group :development do
  gem 'pry', '~> 0.9' # Ruby 1.8.7 support dropped in pry > 0.10
end

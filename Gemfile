source "http://rubygems.org"

gem 'rake', "~> 10.5.0"
gem 'activesupport', "< 4.0.0"
gem 'i18n', "~> 0.6.11" # Required by activesupport
gem 'nokogiri', "~> 1.5.0"
gem 'mechanize', '0.9.2'
# Force using this version of hpricot so Marshal.dump of PageProxy object doesn't fail. Ugh.
gem 'hpricot', "= 0.6.164"
gem 'htmlentities'
gem 'json', "~> 1.8.6"

gem 'builder', '2.1.2'
gem 'log4r'

gem 'rmagick', "~> 2.16.0"
# Travis was complaining this was missing from the Gemfile. Do we really need it?
gem 'hoe'

gem 'mysql'

group :test do
  gem 'rspec', "~> 2.11.0"
  gem 'rcov', "~> 0.9.10"
end

group :development do
  gem 'pry', '~> 0.10.4' # Ruby 1.8.7 support dropped in pry > 0.10
end

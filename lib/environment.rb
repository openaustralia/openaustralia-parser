# Set specific versions of gems that are needed here.
# This avoids spreading it out throughout the codebase

require 'rubygems'
gem 'activesupport'
gem 'mechanize', "= 0.9.2"
# Force using this version of hpricot so Marshal.dump of PageProxy object doesn't fail. Ugh.
gem 'hpricot', "= 0.6.164"
gem 'htmlentities'

gem 'builder', '2.1.2'
gem 'log4r'

gem 'rspec'
gem 'rcov'

gem 'rmagick'

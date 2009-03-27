# Set specific versions of gems that are needed here.
# This avoids spreading it out throughout the codebase

require 'rubygems'
gem 'activesupport', ">= 2.2"
# Not moving over to Mechanize 0.9 quite yet (as that uses nokogiri rather than hpricot by default)
gem 'mechanize', "= 0.8.5"

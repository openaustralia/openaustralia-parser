#!/usr/bin/env ruby
# A simple list (temporary) test script to dump the contents of the postcode
# database to standard out for testing that the MySQL gem is properly installed.

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'csv'
require 'mysql'
require 'configuration'
require 'people'

conf = Configuration.new

db = Mysql.real_connect(conf.database_host, conf.database_user, conf.database_password, conf.database_name)

res = db.query("SELECT * FROM postcode_lookup")
res.each do |a|
  puts "#{a[0]} => #{a[1]}"
end

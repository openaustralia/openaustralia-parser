# Load the postcode data directly into the database

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'csv'
require 'mysql'
require 'configuration'

conf = Configuration.new

def quote_string(s)
  s.gsub(/\\/, '\&\&').gsub(/'/, "''") # ' (for ruby-mode)
end

db = Mysql.real_connect(conf.database_host, conf.database_user, conf.database_password, conf.database_name)

data = CSV.readlines("data/postcodes.csv")
# Remove the first two elements
data.shift
data.shift

# Clear out the old data
db.query("DELETE FROM postcode_lookup")

values = data.map {|row| "('#{row[0]}', '#{quote_string(row[1])}')" }.join(',')
db.query("INSERT INTO postcode_lookup (postcode, name) VALUES #{values}")

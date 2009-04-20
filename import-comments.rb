#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'configuration'
require 'mysql'
require 'csv'

conf = Configuration.new

db = Mysql.real_connect(conf.database_host, conf.database_user, conf.database_password, conf.database_name)

data = CSV.readlines("exported-comments.csv")
data.each do |row|
  comment_id, user_id, visible, modflagged, posted, hdate, comment_body, hansard_body = row
  quoted = hansard_body.gsub('"', '\"')
  res = db.query("select epobject.epobject_id from epobject, hansard where hansard.hdate=\"#{hdate}\" and epobject.body LIKE \"#{quoted}%\" and epobject.epobject_id = hansard.epobject_id")
  if res.num_rows == 0
    puts "ERROR: No match for text: #{hansard_body} in comment_id: #{comment_id}"
  elsif res.num_rows > 1
    puts "ERROR: More than one match for text: #{hansard_body} in comment_id: #{comment_id}"
  else
    epobject_id = res.fetch_hash["epobject_id"]

    gid = db.query("select gid from hansard where epobject_id=\"#{epobject_id}\"").fetch_hash["gid"]

    # Reinsert the comments back into the database
    quoted = comment_body.gsub('"', '\"')
    db.query("insert into comments (comment_id, user_id, epobject_id, body, posted, modflagged, visible, original_gid) VALUES (\"#{comment_id}\", \"#{user_id}\", \"#{epobject_id}\", \"#{quoted}\", \"#{posted}\", \"#{modflagged}\", \"#{visible}\", \"#{gid}\")")
  end
end

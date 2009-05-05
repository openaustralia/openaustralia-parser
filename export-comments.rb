#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'environment'
require 'configuration'
require 'mysql'
require 'csv'

conf = Configuration.new

db = Mysql.real_connect(conf.database_host, conf.database_user, conf.database_password, conf.database_name)

res = db.query("select comments.*, comments.body as comment_body, epobject.body as hansard_body, hdate from comments, epobject, hansard where hansard.epobject_id = epobject.epobject_id and comments.epobject_id = epobject.epobject_id")

outfile = File.open('exported-comments.csv', 'wb')
CSV::Writer.generate(outfile) do |csv|
  res.each_hash do |row|
    csv << [row["comment_id"], row["user_id"], row["visible"], row["modflagged"], row["posted"], row["hdate"], row["comment_body"], row["hansard_body"][0..300]]
  end
end
outfile.close

db.query("DELETE FROM comments")

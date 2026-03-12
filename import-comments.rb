#!/usr/bin/env ruby
# frozen_string_literal: true
#
# mlander: Very rough and ready scripts for importing/exporting comments when gid's might change
#
# FIXME: We shouldn't be dependent on GIDs staying the same as replication fallover may change them

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"

require "csv"

require "configuration"
require "mysql"

class ImportComments
  def initialize(args)
    @args = args
  end

  def run
    puts "WARNING: [mlander:] These are Very rough and ready scripts for importing/exporting comments when gid's might change!"
    if ENV['BE-DANGEROUS']
      puts "Continuing..."
    else
      puts "Set BE-DANGEROUS=1 if you have read these scripts and know what you are doing!"
      exit(1)
    end
    conf = Configuration.new

    db = Mysql.real_connect(conf.database_host, conf.database_user, conf.database_password,
                            conf.database_name)

    data = CSV.readlines("exported-comments.csv")
    data.each do |row|
      comment_id, user_id, visible, modflagged, posted, hdate, comment_body, hansard_body = row
      quoted = hansard_body.gsub('"', '\"')
      res = db.query("select epobject.epobject_id from epobject, hansard where hansard.hdate=\"#{hdate}\" and epobject.body LIKE \"#{quoted}%\" and epobject.epobject_id = hansard.epobject_id")
      if res.num_rows.zero?
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
  end
end

ImportComments.new(ARGV).run if $PROGRAM_NAME == __FILE__

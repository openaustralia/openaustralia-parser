#!/usr/bin/env ruby
# frozen_string_literal: true

# FIXME: We shouldn't be dependent on GIDs staying the same as replication fallover may change them

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"

require "csv"

require "configuration"
require "mysql"

class ExportComments
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

    res = db.query("select comments.*, comments.body as comment_body, epobject.body as hansard_body, hdate from comments, epobject, hansard where hansard.epobject_id = epobject.epobject_id and comments.epobject_id = epobject.epobject_id")
    puts "Creating exported-comments.csv from selected rows in comments table..."
    outfile = File.open("exported-comments.csv", "wb")
    CSV::Writer.generate(outfile) do |csv|
      res.each_hash do |row|
        csv << [row["comment_id"], row["user_id"], row["visible"], row["modflagged"], row["posted"], row["hdate"],
                row["comment_body"], row["hansard_body"][0..300]]
      end
    end
    outfile.close

    puts "Clearing comments table..."
    db.query("DELETE FROM comments")
  end
end

exit ExportComments.new(ARGV).run if $PROGRAM_NAME == __FILE__

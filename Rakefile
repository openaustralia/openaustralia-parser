# frozen_string_literal: true

require "fileutils"
require "rake"
require "rspec/core/rake_task"

require_relative "lib/configuration"

task default: [:spec]

RSpec::Core::RakeTask.new(:spec)

namespace :db do
  desc "Dump database to tmp/backup.sql using mysqldump"
  task :dump do
    conf = Configuration.new
    output = "tmp/db_dump.sql"

    FileUtils.mkdir_p("tmp")

    # Suitable for RDS database, works on production
    cmd = [
      "mysqldump",
      "--single-transaction",
      "--no-tablespaces",
      "--set-gtid-purged=OFF",
      "-h", conf.database_host,
      "-u", conf.database_user,
      "-p#{conf.database_password}",
      conf.database_name,
      "> #{output}"
    ].join(" ")

    puts "Dumping #{conf.database_name} to #{output}..."
    system(cmd) or abort("mysqldump failed")
    puts "Done: created #{output} (#{File.size(output)} bytes)"
  end
end

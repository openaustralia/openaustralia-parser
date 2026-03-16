# frozen_string_literal: true

require "fileutils"
require_relative "../configuration"

namespace :db do
  task :connection do
    require "logger"
    require "active_record"
    conf = Configuration.new
    ActiveRecord::Base.establish_connection(
      adapter: "mysql2",
      host: conf.database_host,
      username: conf.database_user,
      password: conf.database_password,
      database: conf.database_name
    )
  end

  desc "Create databases"
  task :create do
    require "logger"
    require "active_record"
    configs = [Configuration.new]
    configs << Configuration.new(app_env: "test") if configs.first.development?

    configs.each do |conf|
      puts "Creating #{conf.database_name}..."
      system("mysql -h #{conf.database_host} -u #{Shellwords.escape(conf.database_user)} --password=#{Shellwords.escape(conf.database_password)} -e 'CREATE DATABASE IF NOT EXISTS #{conf.database_name};'")
      # system("mysql -h #{conf.database_host} -u root -p -e 'GRANT ALL PRIVILEGES ON #{conf.database_name}.* TO #{conf.database_user}@localhost;'")
    end
    # system("mysql -h #{configs.first.database_host} -u root -p -e 'FLUSH PRIVILEGES;'")
  end

  desc "Drop databases"
  task :drop do
    require "logger"
    require "active_record"
    configs = [Configuration.new]
    configs << Configuration.new(app_env: "test") if configs.first.development?

    configs.each do |conf|
      if conf.production? && !ENV["DISABLE_DATABASE_ENVIRONMENT_CHECK"]
        abort "Refusing to drop production database! Set DISABLE_DATABASE_ENVIRONMENT_CHECK=1 to override."
      end
      puts "Dropping #{conf.database_name}..."
      system("mysql -h #{conf.database_host} -u #{Shellwords.escape(conf.database_user)} --password=#{Shellwords.escape(conf.database_password)} -e 'DROP DATABASE IF EXISTS #{conf.database_name};'")
    end
  end

  desc "Show row counts for all tables"
  task stats: :connection do
    conn = ActiveRecord::Base.connection
    db_name = conn.current_database
    heading_fmt = "%-30s %8s"
    row_fmt = "%-30s %8d"
    puts format(heading_fmt, "Table", "Count")
    puts format(heading_fmt, "-" * 30, "-" * 8)
    conn.tables.sort.each do |t|
      sql = if ENV["EXACT_COUNT"]
              "SELECT COUNT(*) FROM `#{t}`"
            else
              "SELECT TABLE_ROWS FROM information_schema.TABLES WHERE TABLE_SCHEMA = '#{db_name}' AND TABLE_NAME = '#{t}'"
            end
      count = conn.exec_query(sql).rows.first[0].to_i
      if count < 100 && ENV["EXACT_COUNT"].nil?
        count = conn.exec_query("SELECT COUNT(*) FROM `#{t}`").rows.first[0].to_i
      end
      puts format(row_fmt, t, count)
    end
    puts "",
         "Status as of #{Time.now.utc}",
         ENV["EXACT_COUNT"] ? "(exact count)" : "(approximate - set EXACT_COUNT=1 for exact)"
  end

  desc "Dump database to tmp/db_dump.sql using mysqldump"
  task :backup do
    conf = Configuration.new
    output = "tmp/backup.sql"
    FileUtils.mkdir_p("tmp")

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
    puts "Done: #{output} (#{File.size(output)} bytes)"
  end

  desc "Dump a representative fixture subset to spec/fixtures/"
  task create_fixtures: :connection do
    conf = Configuration.new
    dir = "spec/fixtures"
    FileUtils.mkdir_p(dir)
    conn = ActiveRecord::Base.connection

    dump_args = "--no-create-info --compact --skip-extended-insert --no-tablespaces"
    mysql_args = "-h #{conf.database_host} -u #{conf.database_user} -p#{conf.database_password} #{conf.database_name}"

    # rough range with not much happening at each end
    from_date = "2011-01-15"
    to_date = "2016-10-30"
    limit = 10
    # excludes sensitive discussion
    exclude_ids = [200638]
    puts "Selecting #{limit} hansard records from #{from_date} onwards and #{limit} recent comments"

    # Lets start with one of each significant grouping
    member_ids = conn.exec_query("SELECT MAX(member_id), min(member_id) FROM member where entered_house between '#{from_date}' and '#{to_date}' group by house, party").rows
    user_ids = conn.exec_query("SELECT MAX(user_id), min(user_id) FROM users where registrationtime between '#{from_date}' and '#{to_date}' group by status, deleted, optin, emailpublic, confirmed").rows
    hansard_ids = conn.exec_query("SELECT MAX(epobject_id), min(epobject_id) FROM hansard WHERE hdate between '#{from_date}' and '#{to_date}' and epobject_id not in (#{exclude_ids.join(',')}) GROUP BY major, htype").rows
    hansard_ids += conn.exec_query("SELECT MAX(epobject_id), min(epobject_id) FROM comments WHERE posted between '#{from_date}' and '#{to_date}' and epobject_id not in (#{exclude_ids.join(',')}) GROUP BY (posted is null),(modflagged is null),visible").rows

    # Add in a small group of limit records in sequence
    member_ids += conn.exec_query("SELECT member_id FROM member WHERE entered_house between '#{from_date}' and '#{to_date}' LIMIT #{limit}").rows
    user_ids += conn.exec_query("SELECT user_id FROM users WHERE registrationtime between '#{from_date}' and '#{to_date}' LIMIT #{limit}").rows
    hansard_ids += conn.exec_query("SELECT epobject_id FROM hansard WHERE hdate between '#{from_date}' and '#{to_date}' and epobject_id not in (#{exclude_ids.join(',')}) LIMIT #{limit}").rows
    hansard_ids += conn.exec_query("SELECT epobject_id FROM comments where posted between '#{from_date}' and '#{to_date}' and epobject_id not in (#{exclude_ids.join(',')}) LIMIT #{limit}").rows

    hansard_ids = hansard_ids.flatten.compact.uniq
    # Add in relationships
    # hansard(speaker_id) => member(member_id),
    member_ids += conn.exec_query("SELECT speaker_id FROM hansard WHERE epobject_id IN (#{hansard_ids.join(',')})").rows
    member_ids = member_ids.flatten.compact.uniq

    # hansard(epobject_id) => comment(subject_id).user_id => user
    user_ids += conn.exec_query("SELECT DISTINCT user_id FROM comments WHERE epobject_id IN (#{hansard_ids.join(',')})").rows
    user_ids = user_ids.flatten.compact.uniq

    # member(constituency) -> postcode_lookup
    constituency = conn.exec_query("SELECT DISTINCT constituency FROM member WHERE member_id IN (#{member_ids.join(',')})").rows
    constituency = constituency.flatten.compact.uniq.map { |c| conn.quote(c) }

    tables = {
      "hansard" => "epobject_id IN (#{hansard_ids.join(',')})",
      "epobject" => "epobject_id IN (#{hansard_ids.join(',')})",
      "member" => "member_id IN (#{member_ids.join(',')})",
      "postcode_lookup" => "name IN (#{constituency.join(',')})",
      "comments" => "epobject_id IN (#{hansard_ids.join(',')})",
      "users" => "user_id IN (#{user_ids.join(',')})"
    }

    firstnames = conn.exec_query("SELECT DISTINCT firstname FROM users").rows.flatten
    firstnames = %w[John Jane] if firstnames.empty?
    lastnames = conn.exec_query("SELECT DISTINCT lastname FROM users").rows.flatten
    lastnames = %w[Doe Smith Jones] if lastnames.empty?

    tables.each do |table, where|
      file = "#{dir}/#{table}.sql"
      if table == "users"
        # scrub users - write manually instead of mysqldump
        rows = conn.exec_query("SELECT * FROM users WHERE user_id IN (#{user_ids.join(',')})").to_a
        File.open(file, "w") do |f|
          rows.each do |row|
            user_id = row["user_id"].to_i
            row["firstname"] = firstnames[user_id % firstnames.size]
            row["lastname"] = lastnames[user_id % lastnames.size]
            row["email"] = "#{row['firstname']}.#{row['lastname']}@example.com"
            row["password"] = "redacted-#{user_id}"
            if row["registrationip"]
              row["registrationip"] =
                "127.#{(user_id / (71 * 53)) % 227}.#{(user_id / 53) % 71}.#{user_id % 53}"
            end
            row["registrationtoken"] = "reg-token-#{user_id}" if row["registrationtoken"]
            row["api_key"] = "api-key-#{user_id}" if row["api_key"]
            row["url"] = "https://example.com" if row["url"]

            # FIXME: twfy/db/schema.sql doesnt match actual database schema and data!!!
            row.delete("postcode")
            row["lastvisit"] ||= "0000-01-01 00:00:00"
            row["registrationtime"] ||= "0000-01-01 00:00:00"
            unless %w[Viewer User Moderator Administrator Superuser].include?(row["status"])
              row["status"] = "Viewer"
            end
            columns = row.keys.map { |k| k.nil? ? "NULL" : "`#{k}`" }.join(", ")
            vals = row.values.map { |v| v.nil? ? "NULL" : conn.quote(v) }.join(", ")

            f.puts "INSERT INTO `#{table}` (#{columns}) VALUES (#{vals});"
          end
        end
        puts "Wrote #{rows.size} scrubbed users -> #{file}"
      else
        cmd = %(mysqldump #{dump_args} --where="#{where}" #{mysql_args} #{table} > #{file})
        puts "Dumping #{table} -> #{file}"
        system(cmd) or abort("Failed on #{table}")
      end
    end

    puts "Done: fixtures written to #{dir}/"
  end

  namespace :fixtures do
    desc "Load spec fixtures into database"
    task load: :connection do
      require_relative "../../spec/support/db_support"
      DbSupport.establish_test_database(force: true)
    end
  end
end

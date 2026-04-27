# frozen_string_literal: true

module DbSupport
  TABLES_NEEDED = %w[postcode_lookup users member hansard comments].freeze

  SCHEMA_FIXTURE = File.expand_path("../fixtures/schema.sql", __dir__)

  def self.schema_file
    %w[twfy openaustralia/twfy].each do |dir|
      path = File.expand_path("../../../#{dir}/db/schema.sql", __dir__)
      unless File.size?(path) &&
             (!File.size?(SCHEMA_FIXTURE) || File.mtime(path) > File.mtime(SCHEMA_FIXTURE))
        next
      end

      puts "NOTE: updating #{SCHEMA_FIXTURE} from newer #{path}!"
      FileUtils.cp(path, SCHEMA_FIXTURE)
    end
    return SCHEMA_FIXTURE if File.exist?(SCHEMA_FIXTURE)

    raise "schema.sql not found in fixtures, ../twfy/db or ../openaustralia/twfy/db"
  end

  def self.extract_create_statements
    sql = File.read(schema_file)
    TABLES_NEEDED.map do |table|
      sql[/CREATE TABLE `#{table}`.*?;/m] or raise "Table '#{table}' not found in schema.sql"
    end
  end

  def self.establish_test_database(force: true)
    require "logger"
    require "active_support"
    require "active_record"
    require_relative "../../lib/configuration"

    conf = Configuration.new

    ActiveRecord::Base.establish_connection(
      adapter: "mysql2",
      host: conf.database_host,
      username: conf.database_user,
      password: conf.database_password,
      database: conf.database_name
    )
    conn = ActiveRecord::Base.connection

    # Drop tables if forced to
    TABLES_NEEDED.reverse.each do |table|
      puts "Dropping #{table} table" if ENV["DEBUG"]
      conn.execute("DROP TABLE IF EXISTS `#{table}`")
    end if force
    # create missing tables
    existing = conn.tables
    extract_create_statements.zip(TABLES_NEEDED).filter_map do |stmt, table|
      if existing.include?(table)
        puts "Truncating #{table} table" if ENV["DEBUG"]
        conn.execute("TRUNCATE TABLE #{table}")
      else
        puts "Creating #{table} table" if ENV["DEBUG"]
        conn.execute(stmt)
      end
    end

    # Populate tables with fixtures
    TABLES_NEEDED.each do |table|
      fixture_path = File.expand_path("../fixtures/#{table}.sql", __dir__)
      next unless File.size?(fixture_path)

      puts "Populating #{table} table" if ENV["DEBUG"]
      File.read(fixture_path).split(/;\s*\n/).each do |stmt|
        next if stmt.strip.empty?

        # puts "STATEMENT: #{stmt}"
        conn.execute(stmt)
      end
    end
  end
end
if defined?(RSpec) && defined?(RSpec.configure)
  RSpec.configure do |config|
    config.include DbSupport

    config.before(:suite) { DbSupport.establish_test_database }

    config.around(:each, :db) do |example|
      ActiveRecord::Base.connection.transaction(requires_new: true) do
        example.run
        raise ActiveRecord::Rollback
      end
    end
  end
end


# frozen_string_literal: true

require_relative "../../lib/configuration"

module DbSupport
  TABLES_NEEDED = %w[postcode_lookup].freeze

  SCHEMA_FIXTURE = File.expand_path("../fixtures/schema.sql", __dir__)

  def self.schema_file
    %w[.. ../openaustralia].each do |dir|
      path = File.expand_path("#{dir}/twfy/db/schema.sql", __dir__)
      if !File.size?(path) || (File.size?(SCHEMA_FIXTURE) && File.mtime(path) <= File.mtime(SCHEMA_FIXTURE))
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

  def self.establish_test_database(load_fixtures: true)
    conf = Configuration.new

    ActiveRecord::Base.establish_connection(
      adapter: "mysql2",
      host: conf.database_host,
      username: conf.database_user,
      password: conf.database_password,
      database: conf.database_name
    )
    conn = ActiveRecord::Base.connection

    TABLES_NEEDED.each { |t| conn.execute("DROP TABLE IF EXISTS `#{t}`") }
    extract_create_statements.each { |stmt| conn.execute(stmt) }

    return unless load_fixtures

    TABLES_NEEDED.each do |table|
      fixture_path = File.expand_path("../fixtures/#{table}.sql", __dir__)
      conn.execute(File.read(fixture_path)) if File.size?(fixture_path)
    end
  end
end

RSpec.configure do |config|
  config.include DbSupport
end

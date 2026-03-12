# spec/support/db_support.rb

require_relative '../../lib/configuration'

module DbSupport
  TABLES_NEEDED = %w[postcode_lookup].freeze

  def self.schema_file
    %w[.. ../openaustralia].each do |dir|
      path = "#{dir}/twfy/db/schema.sql"
      return path if File.size?(path)
    end
    raise "schema.sql file not found in ../twfy/db or ../openaustralia/twfy/db"
  end

  def self.extract_create_statements
    sql = File.read(schema_file)
    TABLES_NEEDED.map do |table|
      sql[/CREATE TABLE `#{table}`.*?;/m] or raise "Table '#{table}' not found in schema.sql"
    end
  end

  def self.establish_test_database(load_fixtures: true)
    conf = Configuration.new

    # Establish the connection to the database
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

    if load_fixtures
      TABLES_NEEDED.each do |table|
        # FIXME - make relative to spec/support/db_support.rb, and is there a better way!?
        fixture_path = "../fixtures/#{table}.sql"
        conn.execute(File.read(fixture_path)) if File.size(fixture_path)
      end
    end
  end
end

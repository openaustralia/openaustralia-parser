# lib/tasks/validate_encoding.rake
# Checks all tables and columns in the DB are using utf8mb4, not utf8 (mb3)
# Outputs ready-to-run SQL to fix any issues found.

namespace :db do
  desc "Validate all tables and columns use utf8mb4 encoding (not utf8/mb3)"
  task validate_encoding: "db:connection" do
    conf = Configuration.new
    conn = ActiveRecord::Base.connection
    db_name = conf.database_name

    bad_tables = {}
    conn.query(<<~SQL).each do |row|
      SELECT table_name, table_collation
      FROM information_schema.tables
      WHERE table_schema = '#{db_name}'
        AND table_type = 'BASE TABLE'
        AND table_collation NOT LIKE 'utf8mb4%'
    SQL
      bad_tables[row[0]] = row[1]
    end

    bad_columns = {}
    conn.query(<<~SQL).each do |row|
      SELECT table_name, column_name, character_set_name, collation_name
      FROM information_schema.columns
      WHERE table_schema = '#{db_name}'
        AND character_set_name IS NOT NULL
        AND character_set_name != 'utf8mb4'
      ORDER BY table_name, column_name
    SQL
      (bad_columns[row[0]] ||= []) << { column: row[1], charset: row[2], collation: row[3] }
    end

    if bad_tables.empty? && bad_columns.empty?
      puts "OK: All tables and columns are utf8mb4"
      next
    end

    fixes = []

    bad_tables.each do |table, collation|
      fixes << "-- TABLE #{table} has collation: #{collation}"
      fixes << "ALTER TABLE #{table} CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
      fixes << ""
    end

    # Skip columns already covered by a table-level fix above
    bad_columns.each do |table, columns|
      next if bad_tables.key?(table)

      columns.each do |col|
        fixes << "-- COLUMN #{table}.#{col[:column]} has charset: #{col[:charset]}, collation: #{col[:collation]}"
      end
      fixes << "ALTER TABLE #{table} CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
      fixes << ""
    end

    puts "FAIL: Found encoding issues. Run the following SQL to fix:\n\n"
    fixes.each { |line| puts line }
    exit 1
  end
end

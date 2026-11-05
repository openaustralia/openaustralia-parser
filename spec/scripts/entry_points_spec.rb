# frozen_string_literal: true

require_relative "../spec_helper"

# A script that starts the wrong class does the wrong job when run, yet still
# passes a syntax check, so compare the two by reading the source.
RSpec.describe "entry scripts" do
  # The line that runs the script when it is started directly
  def self.entry_line(path)
    File.readlines(path).find { |line| line.match?(/\$PROGRAM_NAME.*__FILE__/) }
  end

  def self.entry_scripts
    Dir[File.expand_path("../../*.rb", __dir__)].select { |path| entry_line(path) }
  end

  # Classes the script defines itself or in the files it loads with require_relative
  def classes_defined_for(path)
    source = File.read(path)
    loaded = source.scan(/^require_relative "(.+)"/).flatten.map { |name| File.expand_path("#{name}.rb", File.dirname(path)) }
    ([source] + loaded.select { |file| File.exist?(file) }.map { |file| File.read(file) })
      .flat_map { |text| text.scan(/^class (\w+)/).flatten }
  end

  it "finds the entry scripts" do
    expect(self.class.entry_scripts.size).to be > 5
  end

  entry_scripts.each do |path|
    it "#{File.basename(path)} starts a class it defines or loads" do
      started_class = self.class.entry_line(path)[/(\w+)\.new\b/, 1]
      expect(classes_defined_for(path)).to include(started_class)
    end
  end
end

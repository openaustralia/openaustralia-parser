#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"

require "configuration"
require "people"
require "optparse"
require "down"

# Defaults
options = {
  load_database: true,
  abs_base_url: "https://www.abs.gov.au/statistics/standards/australian-statistical-geography-standard-asgs-edition-3/jul2021-jun2026/access-and-downloads/allocation-files/",
  abs_excel_files: {
    local_govt_areas: "LGA_2021_AUST.xlsx",
    state_electoral_div: "SED_2021_AUST.xlsx",
    fed_electoral_div: "CED_2021_AUST.xlsx",
    postal_areas: "POA_2021_AUST.xlsx",
    suburbs_localities: "SAL_2021_AUST.xlsx"
  }
}

# command options
OptionParser.new do |opts|
  opts.banner = "Usage: parse-abs.rb"
end.parse!

puts "Download ABS Excel files"

# the files are all under 20MB
max_size = 20 * 1024 * 1024
dest_dir = "./abs_files"

Dir.mkdir(dest_dir) unless Dir.exist?(dest_dir)

abs_base_url = options[:abs_base_url]
options[:abs_excel_files].each do |key, name|
  dest_file = File.join(dest_dir, name)
  if File.exist?(dest_file)
    puts "Already have #{key}"
  else
    source_url = abs_base_url + name
    Down.download(
      source_url,
      destination: dest_file,
      max_size: max_size,
      content_length_proc: ->(_content_length) { puts "Download #{key}" }
    )
  end
end

puts "Check csv files are present"

csv_files_missing = []
options[:abs_excel_files].each do |_, name|
  dest_file = File.join(dest_dir, name)
  csv_file = Pathname(dest_file).sub_ext(".csv")
  csv_files_missing << csv_file unless csv_file.exist?
end

# TODO: I could not find a gem to convert Excel files to csv in a reasonable time.
# I tried 'roo' and 'xsv', they both took a very long time.
# In the end, I opened the .xlsx files in Excel / OpenOffice and saved as .csv.

raise "Csv files missing #{csv_files_missing}" unless csv_files_missing.empty?

data = {}
options[:abs_excel_files].each do |key, name|
  puts "Read #{key}"

  dest_file = File.join(dest_dir, name)
  csv_file = Pathname(dest_file).sub_ext(".csv")
  headers = nil
  CSV.foreach(csv_file.to_s, headers: true, header_converters: :symbol) do |row|
    headers ||= row.headers

    mb_id = row[:mb_code_2021]
    unless data.key?(mb_id)
      data[mb_id] = {
        state_code_2021: [],
        state_name_2021: [],
        ced_code_2021: [],
        ced_name_2021: [],
        lga_code_2021: [],
        lga_name_2021: [],
        poa_code_2021: [],
        poa_name_2021: [],
        sal_code_2021: [],
        sal_name_2021: [],
        sed_code_2021: [],
        sed_name_2021: []
      }
    end

    data_row = data[mb_id]
    data_row.each_key do |key|
      next unless row[key]

      cell_value = row[key]
      data_row[key] << cell_value unless data_row[key].include?(cell_value)
    end
  end
end

puts "Adjust data before saving to csv"

data.each_value do |i|
  i.each_value do |j|
    next if j.size < 2
    # the islands and bays that are part of Australia are in both 'other territories' and one of NT and ACT
    # for the purposes of making the csv file (and searching for the federal electorate), remove 'other territories'
    if j.include?("Other Territories")
      j.delete("Other Territories")
    elsif j.include?("9")
      j.delete("9")
    end
  end
end

more_then_one_item = data.values.filter { |i| i.values.any? { |j| j.size > 1 } }
raise "More than one item #{more_then_one_item}" unless more_then_one_item.empty?

puts "Remove duplicates"

csv_data = data.map do |_, values|
  values.values
end.uniq

puts "Save to csv file"

csv_file = File.absolute_path(File.join(dest_dir, "data.csv"))
CSV.open(csv_file, "w") do |csv|
  csv << %i[state_code_2021
            state_name_2021
            ced_code_2021
            ced_name_2021
            lga_code_2021
            lga_name_2021
            poa_code_2021
            poa_name_2021
            sal_code_2021
            sal_name_2021
            sed_code_2021
            sed_name_2021]
  csv_data.each do |row|
    csv << row.flatten
  end
end

puts "Finished - csv file saved to #{csv_file}"

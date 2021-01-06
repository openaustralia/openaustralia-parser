#!/usr/bin/env ruby
# frozen_string_literal: true

#
# This splits and combines several large pdfs containing the Register of Members' Interests into one pdf per Senator/Member
#
# Requirement: pdftk (http://www.accesspdf.com/pdftk/)
#
# On Mac OS X 10.5 the latest Macports version kept segfaulting. Installing the pre-compiled
# version from http://www.pdfhacks.com/pdftk/OSX-10.3/pdftk1.12_OSX10.3.dmg.gz worked.

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"

require "csv"
require "name"
require "people"
require "configuration"

# Full path to pdftk executable
pdftk = "/usr/local/bin/pdftk"

people = PeopleCSVReader.read_members

conf = Configuration.new
PageRange = Struct.new(:filename, :start, :end)

def read_in_ranges(p, filename_prefix, people)
  pdf_filename = "data/register_of_interests/#{filename_prefix}.pdf"
  split_filename = "data/register_of_interests/#{filename_prefix}.split"

  # Read in one split file
  data = CSV.readlines(split_filename)
  # Throw away first line (comment)
  data.shift

  data.each_index do |i|
    start_page, last_name, first_name, date_text = data[i]
    start_page = start_page.to_i
    end_page = if i + 1 < data.size
                 data[i + 1][0].to_i - 1
               else
                 "end"
               end
    # Ignore page ranges marked as blank
    next if last_name.downcase == "** blank page **"

    name = Name.last_title_first("#{last_name} #{first_name}")
    # member = people.find_member_by_name_current_on_date(name, date, house)
    if date_text
      date = Date.parse(date_text)
      person = people.find_person_by_name_current_on_date(name, date)
    else
      person = people.find_person_by_name(name)
    end
    raise "Couldn't find #{name.full_name}" if person.nil?

    p[person] ||= []
    p[person] << PageRange.new(pdf_filename, start_page, end_page)
  end
end

# Hash from person to array of page ranges
p = {}

read_in_ranges(p, "senate/2008_09_vol_1", people)
read_in_ranges(p, "senate/2008_09_vol_2", people)
read_in_ranges(p, "senate/2008_12", people)
read_in_ranges(p, "senate/2009_06", people)
read_in_ranges(p, "senate/2009_11", people)
read_in_ranges(p, "senate/2010_06", people)
read_in_ranges(p, "senate/2010_12", people)
read_in_ranges(p, "representatives/2008_03_vol_1", people)
read_in_ranges(p, "representatives/2008_03_vol_2", people)
read_in_ranges(p, "representatives/2008_03_vol_3", people)
read_in_ranges(p, "representatives/2008_03_vol_4", people)
read_in_ranges(p, "representatives/2008_03_vol_5", people)
read_in_ranges(p, "representatives/2008_03_vol_6", people)
read_in_ranges(p, "representatives/2008_03_vol_7", people)
read_in_ranges(p, "representatives/2008_03_vol_8", people)
read_in_ranges(p, "representatives/2008_06", people)

read_in_ranges(p, "representatives/2008_12", people)
read_in_ranges(p, "representatives/2009_03", people)
read_in_ranges(p, "representatives/2009_06", people)
read_in_ranges(p, "representatives/2009_11", people)
read_in_ranges(p, "representatives/2010_03", people)
read_in_ranges(p, "representatives/2010_06", people)
read_in_ranges(p, "representatives/2010_07_wayne_swan", people)
read_in_ranges(p, "representatives/2012_09_martin_ferguson", people)

# Copy across the individual update files
FileUtils.cp("data/register_of_interests/senate/2010_06.pdf", "#{conf.base_dir}#{conf.regmem_pdf_path}/update_senate_2010_06.pdf")
FileUtils.cp("data/register_of_interests/senate/2010_12.pdf", "#{conf.base_dir}#{conf.regmem_pdf_path}/update_senate_2010_12.pdf")

# Now step through all the people and create the pdfs
p.each do |person, ranges|
  filenames = []
  pages = []
  ranges.each_index do |i|
    letter = "A"
    letter[0] = letter[0] + i
    filenames << "#{letter}=#{ranges[i].filename}"
    pages << "#{letter}#{ranges[i].start}-#{ranges[i].end}"
  end
  filenames = filenames.join(" ")
  pages = pages.join(" ")
  command = "#{pdftk} #{filenames} cat #{pages} output #{conf.base_dir}#{conf.regmem_pdf_path}/register_interests_#{person.id_count}.pdf"
  puts "Splitting and combining pdfs for #{person.name.full_name}..."
  system(command)
end

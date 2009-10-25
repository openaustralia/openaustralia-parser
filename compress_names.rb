#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'environment'
require 'name'
require 'csv'

data = CSV.readlines("data/people.csv")
data.shift
data.shift

CSV.open("data/people2.csv", "w") do |writer|
  writer << ["person count", "aph id", "name", "birthday", "alt name"]
  writer << []
  
  data.each do |line|
    if line[0][0..0] == '#'
      # This line is a comment. Should output identically
      writer << line.compact
    else
      person_count, aph_id, title, lastname, firstname, middlename, post_title, birthday = line[0..7]
      name = Name.new(:last => lastname, :first => firstname, :middle => middlename, :title => title, :post_title => post_title)

      # You can specify multiple alternate names by filling out the next columns
      alternate_names = []
      line[8..-1].each_slice(4) do |slice|
        alt_title, alt_lastname, alt_firstname, alt_middlename = slice
        if alt_title || alt_lastname || alt_firstname || alt_middlename
          alternate_names << Name.new(:title => alt_title, :first => alt_firstname, :middle => alt_middlename, :last => alt_lastname)
        end
      end
      
      writer << [person_count, aph_id, name.full_name, birthday] + alternate_names.map{|n| n.full_name}
    end
  end
end

data = CSV.readlines("data/representatives.csv")
data.shift
data.shift

CSV.open("data/representatives2.csv", "w") do |writer|
  writer << ["member count","person count","name","Division","State/Territory","Date of election","Type of election","Date ceased to be a Member","reason","Most recent party"]
  writer << []
  
  data.each do |line|
    if line[0][0..0] == '#'
      # This line is a comment. Should output identically
      writer << line.compact
    else
      member_count, person_count, title, lastname, firstname, middlename, house, division, state, start_date, start_reason, end_date, end_reason, party = line
      name = Name.new(:last => lastname, :first => firstname, :middle => middlename, :title => title)
      
      raise "Unexpected value for house" unless house == "representatives"
      writer << [member_count, person_count, name.full_name, division, state, start_date, start_reason, end_date, end_reason, party]
    end
  end
end

data = CSV.readlines("data/senators.csv")
data.shift
data.shift

CSV.open("data/senators2.csv", "w") do |writer|
  writer << ["member count","person count","name","Division","State/Territory","Date of election","Type of election","Date ceased to be a Member","reason","Most recent party"]
  writer << []
  
  data.each do |line|
    if line[0][0..0] == '#'
      # This line is a comment. Should output identically
      writer << line.compact
    else
      member_count, person_count, title, lastname, firstname, middlename, house, division, state, start_date, start_reason, end_date, end_reason, party = line
      name = Name.new(:last => lastname, :first => firstname, :middle => middlename, :title => title)
      
      raise "Unexpected value for house" unless house == "senate"
      writer << [member_count, person_count, name.full_name, division, state, start_date, start_reason, end_date, end_reason, party]
    end
  end
end
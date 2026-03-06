#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/hpricot_additions'
require_relative 'lib/hansard_rewriter'
require 'log4r'
require 'nokogiri'

# Setup logging to see warnings
logger = Log4r::Logger.new('TestHansardParser')
logger.add Log4r::StdoutOutputter.new('console')

bad_xml = File.open('spec/fixtures/bad-dates.xml').read
rewriter = HansardRewriter.new(logger)
rewritten = rewriter.rewrite_xml(Nokogiri::XML(bad_xml))

# Look for talker
talker = rewritten.at('talker')
puts "Found talker: #{talker.inspect}"

# Look for speeches
speeches = rewritten.xpath('//speech')
puts "Found #{speeches.length} speech elements"

# Look for questions/answers
questions = rewritten.xpath('//question')
answers = rewritten.xpath('//answer')
puts "Found #{questions.length} question elements"
puts "Found #{answers.length} answer elements"

# Print the debate structure
debates = rewritten.xpath('//debate')
if debates.length > 0
  puts "\nDebate children:"
  debates[0].children.each do |child|
    puts "  - #{child.name}"
  end
end

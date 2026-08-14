#!/usr/bin/env ruby
# frozen_string_literal: true

# Generate sitemap.xml for quick and easy search engine updating
# This script is run as part of twfy/scripts/morningupdate

require "bundler/setup"

require "logger"

require "active_record"
require "builder"
require "English"
require "json"
require "net/http"
require "yaml"
require "zlib"

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"

require_relative "lib/sitemap_generator"

args = ARGV.dup # make a copy of ARGV so that OptionParser doesn't modify the original

SitemapGenerator.new(args).run if $PROGRAM_NAME == __FILE__

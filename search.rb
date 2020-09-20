#!/usr/bin/ruby
# coding: utf-8

require "./common"

def usage
  puts <<"__EOM__"
Usage: #{$0} search_word
You must run create_index.rb to create search index file before using this command.
__EOM__
end

if ARGV.length < 1
  usage
  exit 1
end

idx = NgramIndex.new

begin
  idx.load
rescue ArgumentError => e
  puts "Error in loading index file: #{e.message}"
  usage
  exit 1
end

idx.search_print(ARGV[0])

#!/usr/bin/ruby
# coding: utf-8

require "./common"

def usage
  puts <<"__EOM__"
Usage: #{$0}
You must put KEN_ALL.CSV csv file in same directory
__EOM__
end

idx = NgramIndex.new
begin
  idx.create
rescue ArgumentError => e
  puts "Error in creating index file: #{e.message}"
  usage
  exit 1
end
idx.save

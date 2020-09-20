#!/usr/bin/ruby
# coding: utf-8

require "./common"

idx = NgramIndex.new
idx.load
idx.search_print("渋谷")

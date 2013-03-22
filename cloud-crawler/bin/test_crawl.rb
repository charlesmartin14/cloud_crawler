#!/usr/bin/env ruby
require 'rubygems'
require 'cloud_crawler'
require 'trollop'

#TODO:  get this to run

opts = Trollop::options do
  opt :urls, "urls to crawl", :multi => true,  :default => "http://www.ehow.com"
end


CloudCrawler::standalone_crawl(opts[:urls])  do |c|
  puts "i am being exec locally"
  c.on_every_page {   puts cache.incr "count" } 
end




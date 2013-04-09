#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
require 'cloud_crawler'
require 'trollop'


opts = Trollop::options do
  opt :urls, "urls to crawl", :short => "-u", :multi => true,  :default => "http://www.livestrong.com"
  opt :flush,  "", :short => "-x", :default => false
  opt :max_slice, "", :short => "-m", :default => 100
  opt :push_to_s3, "", :short => "-p", :default => false
  opt :dump_rdb, "", :short => "-d", :default => "/var/lib/redis/dump-6379.rdb"
  opt :discard_page_bodies, "discard page bodies after processing?",  :short => "-x", :default => true
end


CloudCrawler::batch_crawl(opts[:urls], opts) 

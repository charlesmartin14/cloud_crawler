#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
require 'cloud_crawler'
require 'trollop'


opts = Trollop::options do
  opt :urls, "urls to crawl", :short => "-u", :multi => true,  :default => "http://www.livestrong.com"
  opt :flush,  "", :short => "-f", :default => true
  opt :max_slice, "", :short => "-m", :default => 1000
  opt :push_to_s3, "", :short => "-p", :default => true
  opt :dump_rdb, "", :short => "-r", :default => "/var/lib/redis/dump-6379.rdb"
  opt :discard_page_bodies, "discard page bodies after processing?",  :short => "-d", :default => true
end


CloudCrawler::batch_crawl(opts[:urls], opts) 

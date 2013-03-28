#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
require 'cloud_crawler'
require 'trollop'


opts = Trollop::options do
  opt :urls, "urls to crawl", :short => "-u", :multi => true,  :default => "http://www.ehow.com"
  opt :flush,  "", :short => "-x", :default => true
  opt :max_slice, "", :short => "-m", :default => 10
end


CloudCrawler::batch_crawl(opts[:urls], opts) 

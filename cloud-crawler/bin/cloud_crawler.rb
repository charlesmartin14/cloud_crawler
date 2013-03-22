#!/usr/bin/env ruby
require 'rubygems'
require 'cloud_crawler'
require 'trollop'


opts = Trollop::options do
  opt :urls, "urls to crawl", :multi => true,  :default => "http://www.ehow.com"
end


CloudCrawler::standalone_crawl(opts[:urls]) 

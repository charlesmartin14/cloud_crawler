#!/usr/bin/env ruby
require 'rubygems'
require 'cloud_crawler'
require 'trollop'

#TODO:  get this to run

opts = Trollop::options do
  opt :urls, "urls to crawl", :short => "-u", :multi => true,  :default => "http://www.ehow.com"
end


CloudCrawler::crawl(opts[:urls]) 



#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
require 'trollop'

require 'cloud_crawler'
require 'cloud_crawler/worker'


opts = Trollop::options do
  opt :qless_host, "", :short => "-h", :default => 'localhost'
  opt :qless_port,"",  :short => "-p", :default => 6379
  opt :qless_db, "", :short => "-d", :default => 0
  opt :qless_queue, "", :short => "-q", :default => "crawl"   # :multi => true
  opt :interval, "", :short => "-i", :default => 5
  opt :job_reserver, "", :short => "-r", :default => 'Ordered'
  opt :verbose, "", :short => "-v", :default => true
end
puts opts
CloudCrawler::Worker.run(opts)



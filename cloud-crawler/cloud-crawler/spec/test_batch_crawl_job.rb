require 'rubygems'
require 'bundler/setup'
require 'qless'
require 'json'
require 'active_support/core_ext'

module CloudCrawler
  class TestBatchCrawlJob

    QUEUE = 'test_queue'
    
    attr_accessor :data, :client, :queue
    
    def initialize(links, opts={}, blocks={})
      @client = Qless::Client.new
      @queue = @client.queues[QUEUE]
  
      @data = {}
      opts[:qless_queue]= QUEUE
      @data[:opts] = opts.to_json
     
      @data[:focus_crawl_block] = [].to_json
      @data[:on_every_page_blocks] = [].to_json
      @data[:skip_link_patterns] =  [].to_json  
      @data[:on_pages_like_blocks] = Hash.new { |hash,key| hash[key] = [] }.to_json
   
      @data[:urls] = [links].flatten.map { |lnk|  { :link =>  lnk } }.to_json
     
      @data.merge! blocks 
    end

  end




end
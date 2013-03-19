require 'rubygems'
require 'bundler/setup'
require 'qless'
require 'json'

module CloudCrawler
  class TestJob

    QNAME = 'test_queue'
    
    attr_accessor :data, :client, :queue
    def initialize(link, referer=nil, depth=nil, opts={})
      @client = Qless::Client.new
      @queue = @client.queues[QNAME]
      
      @data = {}
      @data[:link], @data[:referer], @data[:depth] = link, referer, depth

      opts[:qless_qname]= QNAME
      @data[:opts] = opts.to_json
      @data[:focus_crawl_block] = [].to_json
      @data[:on_every_page_blocks] = [].to_json
      @data[:on_pages_like_blocks] = Hash.new { |hash,key| hash[key] = [] }.to_json
      @data[:skip_link_patterns] = [].to_json
    end

  end

end
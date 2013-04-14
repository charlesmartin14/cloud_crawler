#!/usr/bin/env ruby
require 'cloud_crawler/dsl_front_end'
require 'cloud_crawler/exceptions'
require 'cloud_crawler/crawl_job'
require 'cloud_crawler/batch_crawl_job'
require 'cloud_crawler/worker'

require 'active_support/inflector'
require 'active_support/core_ext'

require 'json'
require 'sourcify' 
require 'qless'

module CloudCrawler

  VERSION = '0.1';

  #
  # Convenience method to start a crawl 
  #
  def CloudCrawler.crawl(urls, opts = {}, &block)
    Driver.crawl(urls, opts, &block)
  end
  
  def CloudCrawler.batch_crawl(urls, opts = {}, &block)
    Driver.batch_crawl(urls, opts, &block)
  end
  
  
  
  #
  # Convenience method to start a crawl in stand alone mode
  #
  def CloudCrawler.standalone_crawl(urls, opts = {}, &block)
    Driver.crawl(urls, opts, &block)
    Worker.run(opts)
  end
  
   #
  # Convenience method to start a batch crawl in stand alone mode
  #
  def CloudCrawler.standalone_batch_crawl(urls, opts = {}, &block)
    Driver.batch_crawl(urls, opts, &block)
    Worker.run(opts)
  end
  
  

   # do I need to make a class ?
   class Driver
     include DslFrontEnd
     
     DRIVER_OPTS = {              
      :qless_host => 'localhost',
      :qless_port => 6379,
      :qless_db => 0,  # not used yet...
      :qless_queue => "crawlq", # only for testing... over-ridden with name of crawl
      :verbose => true,
      :interval => 10,
      :job_reserver => 'Ordered'
     }
    
    
  
    def initialize(opts = {}, &block)
      opts.reverse_merge! DRIVER_OPTS
      opts[:qless_queue] = opts[:name]  unless opts[:name].nil? or opts[:name].empty?
      init(opts)
      
      @client = Qless::Client.new( :host => opts[:qless_host], :port => opts[:qless_port] )
      @queue = @client.queues[opts[:qless_queue]]
      yield self if block_given?
    end

    #
    # Convenience method to start a new crawl
    #
   def self.crawl(urls, opts = {}, &block)
        self.new(opts) do |core|
          yield core if block_given?
          core.load_urls(urls)
        end
      end

   #
   # Currently, we assume all crawls are simple spiders from a small set of urls
   #  this will change 
   #
      
   def load_urls(urls)
      urls = [urls].flatten.map{ |url| url.is_a?(URI) ? url : URI(url) }
      urls.each{ |url| url.path = '/' if url.path.empty? }
      data = block_sources
      data[:opts] = @opts.to_json
      urls.each do |url|
        data[:link] = url.to_s
        @queue.put(CrawlJob, data)
      end
    end


 def self.batch_crawl(urls, opts = {}, &block)
      self.new(opts) do |core|
        yield core if block_given?
        core.load_batch_urls(urls)
      end
    end
      
      
      def load_batch_urls(urls)
        urls = [urls].flatten.map{ |url| url.is_a?(URI) ? url : URI(url) }
      urls.each{ |url| url.path = '/' if url.path.empty? }
      
      data = block_sources
      data[:opts] = @opts.to_json   # does qless deep serialize out data for us?
      data[:urls] = urls.map { |url|  { :link => url.to_s } }.to_json 
      @queue.put(BatchCrawlJob, data)
      end
    
  end
end





require 'cloud_crawler/dsl_front_end'
require 'cloud_crawler/exceptions'
require 'cloud_crawler/crawl_job'
require 'active_support/inflector'
require 'active_support/core_ext'
require 'sourcify, > 0.6' #
require 'json'
require 'qless'

module CloudCrawler

  VERSION = '0.1';

  #
  # Convenience method to start a crawl in stand alone mode
  #
  def CloudCrawler.crawl(urls, options = {}, &block)
    Driver.crawl(urls, options, &block)
  end

   # do I need to make a class ?
   class Driver
     include DslFrontEnd
     
     DRIVER_OPTS = {     
      :qless_host => 'localhost',
      :qless_port => 1234,
      :qless_qname => "crawl"
     }
    
    
  
    def initialize(opts = {})
      opts.reverse_merge! DRIVER_OPTS
      @client = Qless::Client.new( :host => opts[:qless_host], :port => opts[:qless_port])
      @queue = client.queues[opts[:qless_qname]]
      yield self if block_given?
    end

    #
    # Convenience method to start a new crawl
    #
    def self.crawl(urls, opts = {})
      init(opts)
      self.new(urls, opts) do |core|
        yield core if block_given?
        core.run
      end
    end

 
    def run
      load_urls(urls)
    end
    
    def load_urls(urls)
        urls = [urls].flatten.map{ |url| url.is_a?(URI) ? url : URI(url) }
        urls.each{ |url| url.path = '/' if url.path.empty? }

        urls.delete_if { |url| !visit_link?(url) }
        
        data = block_sources

        urls.each do |url|
          data[:link] = url
          @queue.put(CrawlJob.new, data)
        end
    end
    
    
   end

end

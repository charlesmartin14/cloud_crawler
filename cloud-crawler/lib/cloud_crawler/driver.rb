require 'cloud_crawler/dsl_front_end'
require 'cloud_crawler/exceptions'
require 'cloud_crawler/crawl_job'
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
  #   block not used yet
  #
  def CloudCrawler.crawl(urls, options = {}, &block)
    Driver.crawl(urls, options, &block)
  end
  
  
  #
  # Convenience method to start a crawl in stand alone mode
  #
  def CloudCrawler.crawl_now(urls, options = {}, &block)
    crawl(urls, options, &block)
    Worker.run(options)  # no block passed, not used yet
  end
  
  

   # do I need to make a class ?
   class Driver
     include DslFrontEnd
     
     DRIVER_OPTS = {     
      :qless_host => 'localhost',
      :qless_port => 6379,
      :qless_qname => "crawl"
     }
    
    
  
    def initialize(opts = {})
      opts.reverse_merge! DRIVER_OPTS
      init(opts)
      @client = Qless::Client.new( :host => opts[:qless_host], :port => opts[:qless_port])
      @queue = @client.queues[opts[:qless_qname]]
      yield self if block_given?
    end

    #
    # Convenience method to start a new crawl
    #
    def self.crawl(urls, opts = {})
      self.new(opts) do |core|
        yield core if block_given?
        core.run(urls)
      end
    end

 
    def run(urls)
      load_urls(urls)
    end
    
    def load_urls(urls)
        urls = [urls].flatten.map{ |url| url.is_a?(URI) ? url : URI(url) }
        urls.each{ |url| url.path = '/' if url.path.empty? }
        
        # TODO:  not picking this up?
        data = block_sources
        urls.each do |url|
          data[:link] = url.to_s
          data[:opts] = @opts.to_json
          @queue.put(CrawlJob, data)
        end
    end
    
    
   end

end

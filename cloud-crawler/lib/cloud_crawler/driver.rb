require 'cloud_crawler/dsl_front_end'
require 'cloud_crawler/exceptions'
require 'cloud_crawler/crawl_job'
require 'cloud_crawler/test_worker'

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
  def CloudCrawler.crawl(urls, opts = {}, &block)
    Driver.crawl(urls, opts, &block)
  end
  
  
  #
  # Convenience method to start a crawl in stand alone mode
  #
  def CloudCrawler.standalone_crawl(urls, opts = {}, &block)
    crawl(urls, opts, &block)
    Worker.run(opts)
  end
  
  

   # do I need to make a class ?
   class Driver
     include DslFrontEnd
     
     DRIVER_OPTS = {              
      :qless_host => 'localhost',
      :qless_port => 6379,
      :qless_db => 0,  # not used yet..not sure how
      :qless_queues => ["crawl"],
      :verbose => true,
      :interval => 10,
      :job_reserver => 'Ordered'
     }
    
    
  
    def initialize(opts = {}, &block)
      opts.reverse_merge! DRIVER_OPTS
      init(opts)
      @client = Qless::Client.new( :host => opts[:qless_host], :port => opts[:qless_port], )
      @queue = @client.queues[opts[:qless_queues].first]
      yield self if block_given?
    end

    #
    # Convenience method to start a new crawl
    #
    def self.crawl(urls, opts = {}, &block)
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
        
        data = block_sources
        data[:opts] = @opts.to_json
        urls.each do |url|
          data[:link] = url.to_s
          @queue.put(CrawlJob, data)
        end
    end
    
    
   end

end



if __FILE__==$0 then
  opts = Trollop::options do
   opt :qless_host,  :short => "-f", :default => DRIVER_OPTS[:qless_host]
   opt :qless_port, :short => "-p", :default => DRIVER_OPTS[:qless_port]
   opt :qless_db, :short => "-d", :default => DRIVER_OPTS[:qless_db]
   opt :qless_queues, :short => "-q", :default => DRIVER_OPTS[:qless_queues], :multi => true
   opt :interval, :short => "-i", :default => DRIVER_OPTS[:interval]
   opt :verbose, :short => "-v", :default => DRIVER_OPTS[:verbose]
  end
 Driver.crawl(opts)
end



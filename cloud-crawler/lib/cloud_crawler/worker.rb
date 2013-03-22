require 'cloud_crawler/exceptions'
require 'qless'

module CloudCrawler


  class Worker
    
     WORKER_OPTS = {     
      :qless_host => 'localhost',
      :qless_port => 6379,
      :qless_qname => "crawl",
      :delay => 1
     }
    
     
    def initialize(opts = {}, &block)
      opts.reverse_merge! WORKER_OPTS
      @opts = opts
      @client = Qless::Client.new( :host => opts[:qless_host], :port => opts[:qless_port])
      @queue = @client.queues[opts[:qless_qname]]
      yield self if block_given?
    end
    
     # Convenience method to start a new crawl
    #
    def self.run(opts= {})
      self.new(opts) do |core|
        yield core if block_given?
        core.run
      end
    end

 
    def run
      while job=@queue.pop
        job.perform
        sleep(@opts[:delay])
      end
    end
    
    
  end
  
end

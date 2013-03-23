require 'qless'
require 'qless/worker'
require 'active_support/core_ext'

#TODO: this is ridiculous
#  if this useful, create a mixin or class that makes this easier does this
#  set command line opts, default opts, and ENV vars all as same input options

module CloudCrawler


  class Worker
    
     WORKER_OPTS = {     
      :qless_host => 'localhost',
      :qless_port => 6379,
      :qless_db => 0,  # not used yet .. not sure how,
      :qless_queues => "crawl",
      :verbose => true,
      :interval => 10,
      :job_reserver => 'Ordered'
     }
    
 
    
   
    def self.run(opts={})
        
      ENV['REDIS_URL']= [opts[:qless_host],opts[:qless_port],opts[:qless_db]].join(":")
      ENV['QUEUES'] = opts[:qless_queues].first
      ENV['JOB_RESERVER'] = opts[:job_reserver]
      ENV['INTERVAL'] = opts[:interval]
      ENV['VERBOSE'] = opts[:verbose]
      
      Qless::Worker::start
    end

 
    
    
  end
  
end


if __FILE__==$0 then
  opts = Trollop::options do
   opt :qless_host,  :short => "-f", :default => WORKER_OPTS[:qless_host]
   opt :qless_port, :short => "-p", :default => WORKER_OPTS[:qless_port]
   opt :qless_db, :short => "-d", :default => WORKER_OPTS[:qless_db]
   opt :qless_queues, :short => "-q", :default => WORKER_OPTS[:qless_queues], :multi => true
   opt :interval, :short => "-i", :default => WORKER_OPTS[:interval]
   opt :verbose, :short => "-v", :default => WORKER_OPTS[:verbose]
  end
 Worker.run(opts)
end






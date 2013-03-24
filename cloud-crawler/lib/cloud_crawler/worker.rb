#!/usr/bin/env ruby
require 'qless'
require 'qless/worker'

module CloudCrawler
  class Worker
    
    def self.run(opts={})
        
      puts opts
      ENV['REDIS_URL']= "redis://#{opts[:qless_host]}:#{opts[:qless_port]}/#{opts[:qless_db]}"
      ENV['QUEUES'] = opts[:qless_queues]
      ENV['JOB_RESERVER'] = opts[:job_reserver]
      ENV['INTERVAL'] = opts[:interval].to_s
      ENV['VERBOSE'] = opts[:verbose].to_s
            
      Qless::Worker::start
    end
    
  end  
end






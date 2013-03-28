#!/usr/bin/env ruby
require 'qless'
require 'qless/worker'

module CloudCrawler
  class Worker
    
    def self.run(opts={})
        
      
      ENV['REDIS_URL']= "redis://#{opts[:qless_host]}:#{opts[:qless_port]}/#{opts[:qless_db]}"
      ENV['QUEUES'] = opts[:qless_queue]
      
    #  ENV['JOB_RESERVER'] = opts[:job_reserver]
      ENV['INTERVAL'] = opts[:interval].to_s
    # ENV['VERBOSE'] = opts[:verbose].to_s
    # ENV['RUN_AS_SINGLE_PROCESS'] = 'true'

      Qless::Worker::start
    end
    
  end  
end





#TODO:  reimplement our own start method
#  wait for redis to come up
#  perdioically poll redis (maybe in another thread)
#  if redis goes down, stop this worker and all child processes (kill?)
# 

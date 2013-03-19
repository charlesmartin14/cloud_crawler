require 'cloud_crawler/http'
require 'cloud_crawler/redis_page_store'
require 'cloud_crawler/dsl_core'
require 'active_support/inflector'
require 'active_support/core_ext'

module CloudCrawler
  
  class CrawlJob
    include DslCore
  
    def self.init(job)
      @page_store = RedisPageStore.new(job.client.redis,@opts)
      @queue = job.client.queues[@opts[:qless_qname]]
    end
  
  
    def self.perform(job)
      super(job)
      init(job)
       
      data = job.data.symbolize_keys
      link, referer, depth = data[:link], data[:referer], data[:depth]
      return if link == :END      

      http = CloudCrawler::HTTP.new(@opts)
      puts "fetching #{link}"
      pages = http.fetch_pages(link, referer, depth)
      pages.each do |page|
         @page_store.touch_url page.url
         
         do_page_blocks page
         page.discard_doc! if @opts[:discard_page_bodies]
         @page_store[page.url] = page
 
         links = links_to_follow page
         links.each do |lnk|
            data[:link], data[:referer], data[:depth] = lnk.to_s,  page.referer,  page.depth + 1
            @queue.put(CrawlJob, data)
         end
        
     end  
    end
   
  end

end
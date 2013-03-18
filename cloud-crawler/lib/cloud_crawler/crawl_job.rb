require 'cloud_crawler/http'
require 'cloud_crawler/redis_page_store'
require 'cloud_crawler/dsl_core'

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
       
      data = job.data
      link, referer, depth = data[:link], data[:referer], data[:depth]
      return if link == :END      

      http = CloudCrawler::HTTP.new(@opts)
      pages = http.fetch_pages(link, referer, depth)
      pages.each do |page|
         @page_store.touch_key page.url
         
         do_page_blocks page
         page.discard_doc! if @opts[:discard_page_bodies]
         @page_store[page.url] = page
 
         links = links_to_follow page
                 
         links.each do |link|
            data[:link], data[:referer], data[:depth] = page.url.dup,  page.referer,  page.depth + 1
            @queue.put(CrawlLinkjob, data)
         end
        
     end  
    end
   
  end

end
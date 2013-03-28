require 'cloud_crawler/http'
require 'cloud_crawler/redis_page_store'
require 'cloud_crawler/redis_url_bloomfilter'
require 'cloud_crawler/dsl_core'
require 'active_support/inflector'
require 'active_support/core_ext'

module CloudCrawler

  # TODO:  crawl links of size N
  # save to local or global cache
  #  DSL:   mcache   master_cache
  #         lcache   local_cache
  #         lpcache  local_persisted_cache
  #         bloomfilter
  #
  class BatchCrawlJob
    include DslCore

    MAX_SLICE_DEFAULT = 100

    # TODO: test locally, then break of queue, bf, and page store
    # url_filter = @url_filter.new  # take bloom filter out of page store
    def self.init(job)
      @key_prefix = @opts[:key_prefix] || 'cc'
      @cache = Redis::Namespace.new("#{@key_prefix}:cache", :redis => job.client.redis)
      @page_store = RedisPageStore.new(job.client.redis,@opts)
      @bloomfilter = RedisUrlBloomfilter.new(job.client.redis,@opts)
      @queue = job.client.queues[@opts[:qless_queue]]
      @max_slice = @opts[:max_slice] || MAX_SLICE_DEFAULT
      @flush =  @opts[:flush] 
    end

    def self.cache
      @cache
    end
    
    
    def self.perform(job)
      super(job)
      init(job)
      
      data = job.data.symbolize_keys
      urls = JSON.parse(data[:urls])
            
      pages = urls.map do |url_data|
        url_data.symbolize_keys!
        link, referer, depth = url_data[:link], url_data[:referer], url_data[:depth]
        next if link.nil? or  link.empty? or link == :END

        http = CloudCrawler::HTTP.new(@opts)
        http.fetch_pages(link, referer, depth)
      end
      
      
      pages.flatten!.compact!

      pages.reject! { |page|  @bloomfilter.visited_url?(page.url.to_s) }
      return if pages.empty?
      

      outbound_urls = []
      pages.each do |page|
        do_page_blocks(page)
        page.discard_doc! if @opts[:discard_page_bodies]

        # cache page locally, we assume
        #  or @page_store << page
        url = page.url.to_s
        @page_store[url] = page

        links = links_to_follow(page)
        links.reject! { |lnk| @bloomfilter.visited_url?(lnk) }
         links.each do |lnk|
          outbound_urls <<{ :link => lnk.to_s, :referer => page.referer.to_s, :depth => page.depth + 1}
        end
      end
            
      # must optionally turn off caching for testing

      # hard, synchronous flush  to s3 (or disk) here
      puts @flush
      saved_urls = if @flush then  @page_store.flush! else @page_store.keys end
      
      # add pages to bloomfilter only if store to s3 succeeds
      saved_urls.each { |url|  @bloomfilter.visit_url(url) }

      outbound_urls.flatten.compact.each_slice(@max_slice) do |urls|
        data[:urls] = urls.to_json
        @queue.put(BatchCrawlJob, data)
      end

    end
  end

end


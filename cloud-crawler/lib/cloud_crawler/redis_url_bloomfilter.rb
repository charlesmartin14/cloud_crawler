require 'redis'
require 'redis-namespace'
require 'bloomfilter-rb'
require 'json'
require 'zlib'
require 'logger'

    
module CloudCrawler
   
  class RedisUrlBloomfilter
    include Enumerable
    
    attr_reader :key_prefix
    
    def initialize(redis, opts = {})
      @redis = redis
      @key_prefix = opts[:key_prefix] || 'cc'
 
      items, bits = 100_000, 5
      opts[:size] ||= items*bits
      opts[:hashes] ||= 7
      opts[:namespace] = "#{name}"
      opts[:db] = redis
      opts[:seed] = 1364249661
      
      # 2.5 mb? 
      @bloomfilter = BloomFilter::Redis.new(opts)
      @log = Logger.new('/tmp/bf.log')
      
    end

   
    def name
      "#{@key_prefix}:url_bf"
    end

    # same as page store
    def key_for(url)
      url.to_s.gsub("https",'http')
    end
    
    
    # bloom filter methods
   
    def touch_url(url)
      @log.info "touch #{url}  #{key_for url}"
      @bloomfilter.insert(key_for url)
      @redis["urls:#{key_for url}"]="touched"
    end
    alias_method :visit_url, :touch_url


    def touch_urls(urls)
      urls.each { |u| touch_url(u) }
    end
    alias_method :visit_urls, :touch_urls 


    def touched_url?(url)
      @log.info "touched? #{url}  #{key_for url}"
      @bloomfilter.include?(key_for url)
      return !@redis["urls:#{key_for url}"].nil?
    end
    alias_method :visited_url?, :touched_url? 


  end
end

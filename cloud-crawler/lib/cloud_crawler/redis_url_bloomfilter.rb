require 'redis'
require 'redis-namespace'
require 'bloomfilter-rb'
require 'json'
require 'zlib'
require 'logger'

    
#TODO:  url = sugar
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
     # @log = Logger.new('/tmp/bf.log')
    end

    # really a bloom filter for anything with sugar
    def name
      "#{@key_prefix}:bf"
    end

    # same as page store
    def key_for(url)
      url.to_s.downcase.gsub("https",'http').gsub(/\s+/,' ')
    end
    
    
    # bloom filter methods
   
    def touch_url(url)
    # @log.info "touch #{url}  #{key_for url}"
        #  @redis["urls:#{key_for url}"]="touched"
     @bloomfilter.insert(key_for url)
    end
    alias_method :visit_url, :touch_url
    alias_method :insert, :touch_url


    def touch_urls(urls)
      urls.each { |u| touch_url(u) }
    end
    alias_method :visit_urls, :touch_urls 
    alias_method :touched?, :touched_url? 


    def touched_url?(url)
    #  @log.info "touched? #{url}  #{key_for url}"
         # return !@redis["urls:#{key_for url}"].nil?
      @bloomfilter.include?(key_for url)
    end
    alias_method :visited_url?, :touched_url? 
    alias_method :include?, :touched_url? 


  end
end

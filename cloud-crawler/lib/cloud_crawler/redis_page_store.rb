require 'redis'
require 'redis-namespace'
require 'bloomfilter-rb'
require 'json'
require 'zlib'

    
module CloudCrawler
  
  
  class RedisPageStore
    include Enumerable
    
    MARSHAL_FIELDS = %w(links visited fetched)
    def initialize(redis, opts = {})
      @redis = redis
      @key_prefix = opts[:key_prefix] || 'c|c'
      @pages = Redis::Namespace.new("#{@key_prefix}:pages", :redis => redis)
      # # keys.each { |key| delete(key) }  # flushdb ?
      #
      items, bits = 100_000, 5
      opts[:size] ||= items*bits
      opts[:hashes] ||= 7
      opts[:namespace] = "#{@key_prefix}:pages_bf"
      opts[:db] = redis
      
      # 2.5 mb? 
      @bloomfilter = BloomFilter::Redis.new opts
    end

    def close
      @redis.quit
    end


    def key_for(url)
      url.to_s.gsub("https",'http')
    end
    
    
    # We typically index the hash with a URI,
    # but convert it to a String for easier retrieval
    def [](url)
      rget key_for url
    end

    def []=(url, page)
      rkey = key_for url
      @pages[rkey]= page.to_hash.to_json
    end

    def delete(url)
      page = self[url]
      @pages.del(key_for url)
      page
    end

    def has_page?(url)
      @pages.exists(key_for url)
    end
    
    def has_key?(key)
      @pages.exists(key)
    end

    def each
      rkeys = @pages.keys("*")
      rkeys.each do |rkey|
        page = rget(rkey)
        url = key_for page.url
        yield url, page
      end
    end

    def merge!(hash)
      hash.each { |key, value| self[key] = value }
      self
    end

    def size
      @pages.keys("*").size
    end

    #TODO: implement and test
    def page_urls

    end

    # when do we do this?  only on serialization
    def each_value
      each { |k, v| yield v }
    end

    def values
      result = []
      each { |k, v| result << v }
      result
    end

    # bloom filter methods
   
    def touch_url(url)
      @bloomfilter.insert(key_for url)
    end
    alias_method :visit_url, :touch_url


    def touch_urls(urls)
      urls.each { |u| touch_url(u) }
    end
    alias_method :visit_urls, :touch_urls 


    def touched_url?(url)
      @bloomfilter.include? key_for url
    end
    alias_method :visited_url?, :touched_url? 


    
# TODO:  make this a qless job, remove it from here
    # #
    # # save snapshot of existing pages to s3
    # # delete pages when done
    # # TODO:  add thread that monitors num pages, runs and serialized
    # # TODO:try to add aws-s3 gem with creds passed on command line?  really?
    # #  first, just check that s3cmd works on current deployment
    # # TODO:  add node id in case multiple saves are occuring (how?)    
    # def serialize_pages!
      # keys = @pages.keys "*"
      # num = keys.size
#       
      # filename = "#{@key_prefix}:pages.#{Time.now.getutc}.jsons.gz"
      # Zlib::GzipWriter.open(filename) do |gz|
         # keys.each { |k| f << @pages[k] }
      # end
#       
      # md5 = Digest::MD5.file(filename).hexdigest  
#           
      # #  better to use aws-s3 library ??
#       
      # tmp_file = "tmp_pages"
      # system "s3cmd put #{filename}"
      # system "s3cmd get #{filename} #{tmp_file}"
# 
      # tmp_md5 = Digest::MD5.file(tmp_file).hexdigest  
#       
      # if md5==tmp_md5 then
        # File.delete(tmp_file)
        # @pages.pipelined do
          # keys.each { |k| @pages.del k }
        # end
      # else
        # num = -1
      # end
#       
#  
      # return num
    # end
#     
    
  
    private

    def rget(rkey)
      Page.from_hash(JSON.parse(@pages[rkey]))
    end

  end
end

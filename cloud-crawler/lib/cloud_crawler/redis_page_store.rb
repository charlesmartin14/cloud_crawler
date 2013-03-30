require 'redis'
require 'redis-namespace'
require 'bloomfilter-rb'
require 'json'
require 'zlib'
module CloudCrawler
  class RedisPageStore
    include Enumerable

    DEFAULT_DUMP_RDB = "/var/lib/redis/dump-6379.rdb"

    attr_reader :key_prefix, :dump_rdb

    MARSHAL_FIELDS = %w(links visited fetched)
    def initialize(redis, opts = {})
      @redis = redis
      @key_prefix = opts[:key_prefix] || 'cc'
      @dump_rdb = opts[:dump_rdb] ||= DEFAULT_DUMP_RDB  # not used yet
      @pages = Redis::Namespace.new(name, :redis => redis)
      @push_to_s3 = opts[:push_to_s3] 
    end

    def close
      @redis.quit
    end

    def name
      "#{@key_prefix}:pages"
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

  

    def keys
      @pages.keys("*")
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

    # # very dangerous if all redis are saved
    # # at least can we place in a seperate db?
    #  wait for this

    # def flush!
    # @redis.save
    # @redis.flushdb
    # end
    #
    # def save
    # @redis.save
    # end

    # simple implementation for testing locally
    def flush!
      keys, filename = save_keys
      push_to_s3!(filename) if @push_to_s3
      delete!(keys)
    end

    # gets a snapshot of the keys
    def save_keys
      #TODO:  add worker id to filename
      filename = "#{@key_prefix}:pages.#{Time.now.getutc.to_s.gsub(/\s/,'')}.jsons.gz"
      Zlib::GzipWriter.open(filename) do |gz|
        keys.each do |k| 
          gz.write @pages[k]
          gz.write "\n"
          end
      end

      return keys, filename

    end

    def push_to_s3!(filename)
      #md5 = Digest::MD5.file(filename).hexdigest

      #  better to use aws-s3 library ??

      #tmp_file = "tmp_pages"
      system "s3cmd put #{filename} s3://cloud-crawler"
      #system "s3cmd get #{filename} #{tmp_file}"

      #tmp_md5 = Digest::MD5.file(tmp_file).hexdigest
      # naively assume succes
      File.delete(filename)

      #return md5==tmp_md5
    end

    # this is so dumb...can't ruby redis cli take a giant list of keys?
    def delete!(keys)
      @pages.pipelined do
        keys.each { |k| @pages.del k }
      end
      return keys
    end

    private

    def rget(rkey)
      Page.from_hash(JSON.parse(@pages[rkey]))
    end

  end
end

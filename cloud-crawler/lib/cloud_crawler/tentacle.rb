require 'cloud_crawler/http'

module CloudCrawler
  class Tentacle

    #
    # Create a new Tentacle
    #
    def initialize(link_queue, page_queue, opts = {})
      @link_queue = link_queue
      @page_queue = page_queue
      @http = CloudCrawler::HTTP.new(opts)
      @opts = opts
      @opts[:link_limit] ||= 100
    end

    #
    # Gets links from @link_queue, and returns the fetched
    # Page objects into @page_queue
    #
    def run
      loop do
        link, referer, depth = @link_queue.deq

        break if link == :END

        @http.fetch_pages(link, referer, depth).each { |page| @page_queue << page }
        delay
      end
    end

    private

    def delay
      sleep @opts[:delay] if @opts[:delay] > 0
      sleep 1 if @link_queue.size > @opts[:link_limit] 
    end

  end
end

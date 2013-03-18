require 'robotex'
require 'sourcify, > 0.6' #
require 'json'
require 'active_support/inflector'
require 'active_support/core_ext'

#TODO:  add relevant default ops
# add DSL parts that make this an actual dsl  return self, etc
# add page store creation

module CloudCrawler
  
  
     DEFAULT_OPTS = {
      # disable verbose output
      :verbose => false,
      # don't throw away the page response body after scanning it for links
      :discard_page_bodies => false,
      # identify self as CloudCrawler/VERSION
      :user_agent => "CloudCrawler/#{CloudCrawler::VERSION}",
      # no delay between requests
      :delay => 0,
      # don't obey the robots exclusion protocol
      :obey_robots_txt => false,
      # by default, don't limit the depth of the crawl
      :depth_limit => false,
      # number of times HTTP redirects will be followed
      :redirect_limit => 5,
      # Hash of cookie name => value to send with HTTP requests
      :cookies => nil,
      # accept cookies from the server and send them back?
      :accept_cookies => false,
      # skip any link with a query string? e.g. http://foo.com/?u=user
      :skip_query_strings => false,
      # proxy server hostname 
      :proxy_host => nil,
      # proxy server port number
      :proxy_port => false,
      # HTTP read timeout in seconds
      :read_timeout => nil,
      
     
      # redis page store
      :page_store_host => 'localhost',
      # redis page store
      :page_store_port => 1234,
      # redis bloomfilter host
      :bloomfilter_ip => 'localhost',
      # redis bloomfilter port
      :bloomfilter_port => 1234
    }



 # does DSL can use instance methods or class instance methods ?
  module DslFrontEnd
     def self.included(base)
      base.send :extend, ClassMethods
    end
 
    module ClassMethods

      def init(opts={})
        @opts = opts.reverse_merge! DEFAULT_OPTS

        @focus_crawl_block = nil
        @on_every_page_blocks = []
        @skip_link_patterns = []
      #  @after_crawl_blocks = []
        @on_pages_like_blocks = Hash.new { |hash,key| hash[key] = [] }
        yield self if block_given?
      end
      
      
      
      def block_sources
        blocks = {}
        blocks[:focus_crawl_block] = @focus_crawl_block.to_source.to_json
        blocks[:on_every_page_blocks] = @on_every_page_blocks.map(&:to_source).to_json
        blocks[:skip_link_patterns] = @skip_link_patterns.map(&:to_source).to_json
      #  blocks[:after_crawl_blocks] = @after_crawl_blocks.map(&:to_source).to_json
        blocks[:on_pages_like_blocks] = @on_pages_like_blocks.each{ |_,a|  a.map!(&:to_source) }.to_json 
        return blocks
      end
      
      #
      # TODO:  figure out what to do with these 
      # Add a block to be executed on the PageStore after the crawl
      # is finished
      #
      # def after_crawl(&block)
        # @after_crawl_blocks << block
        # self
      # end

      #
      # Add one ore more Regex patterns for URLs which should not be
      # followed
      #
      def skip_links_like(*patterns)
        @skip_link_patterns.concat [patterns].flatten.compact
        self
      end

      #
      # Add a block to be executed on every Page as they are encountered
      # during the crawl
      #
      def on_every_page(&block)
        @on_every_page_blocks << block
        self
      end

      #
      # Add a block to be executed on Page objects with a URL matching
      # one or more patterns
      #
      def on_pages_like(*patterns, &block)
        if patterns
          patterns.each do |pattern|
            @on_pages_like_blocks[pattern] << block
          end
        end
        self
      end

      #
      # Specify a block which will select which links to follow on each page.
      # The block should return an Array of URI objects.
      #
      def focus_crawl(&block)
        @focus_crawl_block = block
        self
      end


    end
  end
  
  module DslCore
    def self.included(base)
      base.send :extend, ClassMethods
    end

    
    
    module ClassMethods
      
      # Qless hook
      def perform(job)
        data = job.data.symbolize_keys
        @opts = JSON.parse(data[:opts]).symbolize_keys
             
        @focus_crawl_block = JSON.parse(data[:focus_crawl_block])
        @on_every_page_blocks = JSON.parse(data[:on_every_page_blocks])
        @on_pages_like_blocks = JSON.parse(data[:on_pages_like_blocks])
        @skip_link_patterns = JSON.parse(data[:skip_link_patterns])
        @after_crawl_blocks = JSON.parse(data[:after_crawl_blocks])
      
        perform_actual(job)
      end
      

     
    
      #
      # Execute the after_crawl blocks
      #
      def do_after_crawl_blocks
        @after_crawl_blocks.each { |block| instance_eval(block).call(@page_store) }
      end

      #
      # Execute the on_every_page blocks for *page*
      #
      def do_page_blocks(page)
        @on_every_page_blocks.each do |block|
          instance_eval(block).call(page)
        end

        @on_pages_like_blocks.each do |pattern, blocks|
          blocks.each { |block| instance_eval(block).call(page) } if page.url.to_s =~ pattern
        end
      end

      #
      # Return an Array of links to follow from the given page.
      # Based on whether or not the link has already been crawled,
      # and the block given to focus_crawl()
      #
      def links_to_follow(page)
        links = @focus_crawl_block ? instance_eval(@focus_crawl_block).call(page) : page.links
        links.select { |link| visit_link?(link, page) }.map { |link| link.dup }
      end

      #
      # Returns +true+ if *link* has not been visited already,
      # and is not excluded by a skip_link pattern...
      # and is not excluded by robots.txt...
      # and is not deeper than the depth limit
      # Returns +false+ otherwise.
      #
      def visit_link?(link, from_page = nil)
        !@page_store.visited_url?(link) &&
        !skip_link?(link) &&
        !skip_query_string?(link) &&
        allowed(link) &&
        !too_deep?(from_page)
      end

      #
      # Returns +true+ if we are obeying robots.txt and the link
      # is granted access in it. Always returns +true+ when we are
      # not obeying robots.txt.
      #
      def allowed(link)
        @opts[:obey_robots_txt] ? @robots.allowed?(link) : true
      rescue
        false
        end

      #
      # Returns +true+ if we are over the page depth limit.
      # This only works when coming from a page and with the +depth_limit+ option set.
      # When neither is the case, will always return +false+.
      def too_deep?(from_page)
        if from_page && @opts[:depth_limit]
          from_page.depth >= @opts[:depth_limit]
        else
        false
        end
      end

      #
      # Returns +true+ if *link* should not be visited because
      # it has a query string and +skip_query_strings+ is true.
      #
      def skip_query_string?(link)
        @opts[:skip_query_strings] && link.query
      end

      #
      # Returns +true+ if *link* should not be visited because
      # its URL matches a skip_link pattern.
      #
      def skip_link?(link)
        @skip_link_patterns.any? { |pattern| link.path =~ pattern }
      end

    end
  end
end

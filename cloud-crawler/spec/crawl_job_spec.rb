$:.unshift(File.dirname(__FILE__))
require 'spec_helper'
require 'redis'
require 'cloud_crawler/crawl_job'
require 'test_job'

module CloudCrawler
  describe CrawlJob do

    before(:each) do
      FakeWeb.clean_registry
      @redis = Redis.new
      @redis.flushdb
      @page_store = RedisPageStore.new(@redis)
      @opts = {}
    end

    def crawl_link(url, opts={})
      job = TestJob.new(url, referer=nil, depth=nil, opts=opts)
      CrawlJob.perform(job)
      @page_store.size.should == 1
      while qjob = job.queue.pop
        qjob.perform
      end
      return @page_store.size
    end

    it "should crawl all the html pages in a domain by following <a> href's" do
      pages = []
      pages << FakePage.new('0', :links => ['1', '2'])
      pages << FakePage.new('1', :links => ['3'])
      pages << FakePage.new('2')
      pages << FakePage.new('3')

      crawl_link(pages[0].url).should == 4
    end

    it "should not follow links that leave the original domain" do
      pages = []
      pages << FakePage.new('0', :links => ['1'], :hrefs => 'http://www.other.com/')
      pages << FakePage.new('1')

      crawl_link(pages[0].url).should == 2
      @page_store.keys.should_not include('http://www.other.com/')
    end

    it "should not follow redirects that leave the original domain" do
      pages = []
      pages << FakePage.new('0', :links => ['1'], :redirect => 'http://www.other.com/')
      pages << FakePage.new('1')

      crawl_link(pages[0].url).should == 2
      @page_store.keys.should_not  include('http://www.other.com/')
    end

    it "should follow http redirects" do
      pages = []
      pages << FakePage.new('0', :links => ['1'])
      pages << FakePage.new('1', :redirect => '2')
      pages << FakePage.new('2')

      crawl_link(pages[0].url).should == 3
    end

    it "should follow with HTTP basic authentication" do
      pages = []
      pages << FakePage.new('0', :links => ['1', '2'], :auth => true)
      pages << FakePage.new('1', :links => ['3'], :auth => true)

      crawl_link(pages.first.auth_url).should == 3
    end

    it "should include the query string when following links" do
      pages = []
      pages << FakePage.new('0', :links => ['1?foo=1'])
      pages << FakePage.new('1?foo=1')
      pages << FakePage.new('1')

      crawl_link(pages[0].url).should == 2
      @page_store.keys.should  include(pages[0].url.to_s)
      @page_store.keys.should_not  include(pages[2].url.to_s)
    end

    it "should not discard page bodies by default" do
      crawl_link(FakePage.new('0').url).should == 1
      @page_store.values.first.doc.should_not be_nil
    end

    it "should optionally discard page bodies to conserve memory" do
      crawl_link(FakePage.new('0').url, {:discard_page_bodies => true})
      @page_store.values.first.doc.should be_nil
    end

  

    # TODO:  create block here and pass in
    # it "should be able to call a block on every page" do
    # pages = []
    # pages << FakePage.new('0', :links => ['1', '2'])
    # pages << FakePage.new('1')
    # pages << FakePage.new('2')
    #
    # count = 0
    # CloudCrawler.crawl(pages[0].url, @opts) do |a|
    # a.on_every_page { count += 1 }
    # end
    #
    # count.should == 3
    # end
    #

    #
    # it "should provide a focus_crawl method to select the links on each page to follow" do
    # pages = []
    # pages << FakePage.new('0', :links => ['1', '2'])
    # pages << FakePage.new('1')
    # pages << FakePage.new('2')
    #
    # core = CloudCrawler.crawl(pages[0].url, @opts) do |a|
    # a.focus_crawl {|p| p.links.reject{|l| l.to_s =~ /1/}}
    # end
    #
    # core.should have(2).pages
    # core.pages.keys.should_not include(pages[1].url)
    # end

 

    it "should optionally obey the robots exclusion protocol" do
      pages = []
      pages << FakePage.new('0', :links => '1')
      pages << FakePage.new('1')
      pages << FakePage.new('robots.txt',
      :body => "User-agent: *\nDisallow: /1",
      :content_type => 'text/plain')

      crawl_link(pages[0].url,{:obey_robots_txt => true})
      urls = @page_store.keys
      urls.should include(pages[0].url)
      urls.should_not include(pages[1].url)
    end


    # CHM  this does not test refer properly...unsure why
    describe "many pages" do
      before(:each) do
        @pages, size = [], 5

        size.times do |n|
        # register this page with a link to the next page
          link = (n + 1).to_s if n + 1 < size
          @pages << FakePage.new(n.to_s, :links => Array(link))
        end
      end

      it "should be able to set cookies to send with HTTP requests" do
        cookies = {:a => '1', :b => '2'}
        crawl_link(@pages[0].url, {:cookies => cookies})
      end

      it "should track the page depth and referer" do
        crawl_link(@pages[0].url)
        previous_page = nil
      
        @pages.each_with_index do |page, i|
          page = @page_store[page.url.to_s]
          puts page.referer
        end
        
      # page.depth.should == i
      # if previous_page then
      # page.referer.to_s.should == previous_page.url.to_s
      # else
      # page.referer.should == ""  # not nil ... could be an issue
      # end
      # previous_page = page
      # end
      end

      it "should optionally limit the depth of the crawl" do
        crawl_link(@pages[0].url, {:depth_limit => 3}).should == 4
      end

    #
    #

    end

  end
end


  # front end dsl tests
    # it "should be able to skip links with query strings" do
    # pages = []
    # pages << FakePage.new('0', :links => ['1?foo=1', '2'])
    # pages << FakePage.new('1?foo=1')
    # pages << FakePage.new('2')
    #
    # core = CloudCrawler.crawl(pages[0].url, @opts) do |a|
    # a.skip_query_strings = true
    # end
    #
    # core.should have(2).pages
    # end
    #
    # it "should be able to skip links based on a RegEx" do
    # pages = []
    # pages << FakePage.new('0', :links => ['1', '2'])
    # pages << FakePage.new('1')
    # pages << FakePage.new('2')
    # pages << FakePage.new('3')
    #
    # core = CloudCrawler.crawl(pages[0].url, @opts) do |a|
    # a.skip_links_like /1/, /3/
    # end
    #
    # core.should have(2).pages
    # core.pages.keys.should_not include(pages[1].url)
    # core.pages.keys.should_not include(pages[3].url)
    # end
    #
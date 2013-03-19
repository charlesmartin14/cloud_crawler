$:.unshift(File.dirname(__FILE__))
require 'spec_helper'
require 'redis'
require 'cloud_crawler/crawl_job'
require 'test_job'

module CloudCrawler
  describe CrawlJob do

    before(:each) do
      FakeWeb.clean_registry
      redis = Redis.new
      redis.flushdb
      @page_store = RedisPageStore.new(redis)
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
      @page_store.keys.should_not  include(pages[2].url)
    end



   it "should not discard page bodies by default" do
  CloudCrawler.crawl(FakePage.new('0').url, @opts).pages.values#.first.doc.should_not be_nil
  end
  
  it "should optionally discard page bodies to conserve memory" do
   core = CloudCrawler.crawl(FakePage.new('0').url, @opts.merge({:discard_page_bodies => true}))
    @page_store.values.first.doc.should be_nil
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
  #
  # it "should optionally delay between page requests" do
  # delay = 0.25
  #
  # pages = []
  # pages << FakePage.new('0', :links => '1')
  # pages << FakePage.new('1')
  #
  # start = Time.now
  # CloudCrawler.crawl(pages[0].url, @opts.merge({:delay => delay}))
  # finish = Time.now
  #
  # (finish - start).should satisfy {|t| t > delay * 2}
  # end
  #
  # it "should optionally obey the robots exclusion protocol" do
  # pages = []
  # pages << FakePage.new('0', :links => '1')
  # pages << FakePage.new('1')
  # pages << FakePage.new('robots.txt',
  # :body => "User-agent: *\nDisallow: /1",
  # :content_type => 'text/plain')
  #
  # core = CloudCrawler.crawl(pages[0].url, @opts.merge({:obey_robots_txt => true}))
  # urls = core.pages.keys
  #
  # urls.should include(pages[0].url)
  # urls.should_not include(pages[1].url)
  # end
  #
  # it "should be able to set cookies to send with HTTP requests" do
  # cookies = {:a => '1', :b => '2'}
  # core = CloudCrawler.crawl(FakePage.new('0').url) do |crawler|
  # crawler.cookies = cookies
  # end
  # core.opts[:cookies].should == cookies
  # end
  #
  # it "should freeze the options once the crawl begins" do
  # core = CloudCrawler.crawl(FakePage.new('0').url) do |crawler|
  # crawler.threads = 4
  # crawler.on_every_page do
  # lambda {crawler.threads = 2}.should raise_error
  # end
  # end
  # core.opts[:threads].should == 4
  # end
  #
  # describe "many pages" do
  # before(:each) do
  # @pages, size = [], 5
  #
  # size.times do |n|
  # # register this page with a link to the next page
  # link = (n + 1).to_s if n + 1 < size
  # @pages << FakePage.new(n.to_s, :links => Array(link))
  # end
  # end
  #
  # it "should track the page depth and referer" do
  # core = CloudCrawler.crawl(@pages[0].url, @opts)
  # previous_page = nil
  #
  # @pages.each_with_index do |page, i|
  # page = core.pages[page.url]
  # page.should be
  # page.depth.should == i
  #
  # if previous_page
  # page.referer.should == previous_page.url
  # else
  # page.referer.should be_nil
  # end
  # previous_page = page
  # end
  # end
  #
  # it "should optionally limit the depth of the crawl" do
  # core = CloudCrawler.crawl(@pages[0].url, @opts.merge({:depth_limit => 3}))
  # core.should have(4).pages
  # end
  # end
  #
  # end
  #
  #
  #
  # describe "options" do
  # it "should accept options for the crawl" do
  # core = CloudCrawler.crawl(SPEC_DOMAIN, :verbose => false,
  # :threads => 2,
  # :discard_page_bodies => true,
  # :user_agent => 'test',
  # :obey_robots_txt => true,
  # :depth_limit => 3)
  #
  # core.opts[:verbose].should == false
  # core.opts[:threads].should == 2
  # core.opts[:discard_page_bodies].should == true
  # core.opts[:delay].should == 0
  # core.opts[:user_agent].should == 'test'
  # core.opts[:obey_robots_txt].should == true
  # core.opts[:depth_limit].should == 3
  # end
  #
  # it "should accept options via setter methods in the crawl block" do
  # core = CloudCrawler.crawl(SPEC_DOMAIN) do |a|
  # a.verbose = false
  # a.threads = 2
  # a.discard_page_bodies = true
  # a.user_agent = 'test'
  # a.obey_robots_txt = true
  # a.depth_limit = 3
  # end
  #
  # core.opts[:verbose].should == false
  # core.opts[:threads].should == 2
  # core.opts[:discard_page_bodies].should == true
  # core.opts[:delay].should == 0
  # core.opts[:user_agent].should == 'test'
  # core.opts[:obey_robots_txt].should == true
  # core.opts[:depth_limit].should == 3
  # end
  #
  # it "should use 1 thread if a delay is requested" do
  # CloudCrawler.crawl(SPEC_DOMAIN, :delay => 0.01, :threads => 2).opts[:threads].should == 1
  # end
  # end
  #
  # end
  # end

  end
end
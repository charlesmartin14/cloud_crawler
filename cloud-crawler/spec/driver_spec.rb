$:.unshift(File.dirname(__FILE__))
require 'spec_helper'
require 'cloud_crawler/driver'
require 'cloud_crawler/redis_page_store'

#TODO: implement simple DSL tests
#  basic crawl
#  crawl with blocks
#  crawl options

module CloudCrawler
  describe Driver do

    before(:each) do
      FakeWeb.clean_registry
      @redis = Redis.new
      @redis.flushdb
      @page_store = RedisPageStore.new(@redis)
      @cache =  Redis::Namespace.new("cc:cache", :redis => @redis)
      @client = Qless::Client.new
      @queue = @client.queues[CloudCrawler::DEFAULT_OPTS[:qless_qname]]
    end

    def run_jobs
      while qjob = @queue.pop
        qjob.perform
      end
    end

    #   shared_examples_for "crawl" do
    it "should crawl all the html pages in a domain by following <a> href's" do
      pages = []
      pages << FakePage.new('0', :links => ['1', '2'])
      pages << FakePage.new('1', :links => ['3'])
      pages << FakePage.new('2')
      pages << FakePage.new('3')

      Driver.crawl(pages[0].url)
      run_jobs
      @page_store.size.should == 4
    end

    it "should be able to call a block on every page" do
      pages = []
      pages << FakePage.new('0', :links => ['1', '2'])
      pages << FakePage.new('1')
      pages << FakePage.new('2')

      count = 0
      Driver.crawl(pages[0].url) do |a|
        a.on_every_page { cache.incr "count" }
      end
   
      run_jobs
      @cache["count"].should == "3"
    end
    
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

  end
end


##
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

# TODO:  re-implement this
# it "should accept options via setter methods in the crawl block" do
# core = CloudCrawler.crawl(SPEC_DOMAIN) do |a|
# a.verbose = false
# a.discard_page_bodies = true
# a.user_agent = 'test'
# a.obey_robots_txt = true
# a.depth_limit = 3
# end
#
# core.opts[:verbose].should == false
# core.opts[:discard_page_bodies].should == true
# core.opts[:delay].should == 0
# core.opts[:user_agent].should == 'test'
# core.opts[:obey_robots_txt].should == true
# core.opts[:depth_limit].should == 3
# end
#


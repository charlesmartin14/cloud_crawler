$:.unshift(File.dirname(__FILE__))
require 'spec_helper'
require 'cloud_crawler/driver'

describe CloudCrawler do

  it "should have a version" do
    CloudCrawler.const_defined?('VERSION').should == true
  end

  it "should return a CloudCrawler::Core from the crawl, which has a PageStore" do
    result = CloudCrawler.crawl(SPEC_DOMAIN)
    result.should be_an_instance_of(CloudCrawler::Driver)
  end

end

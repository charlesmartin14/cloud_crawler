require 'cloud_crawler'

begin
  # make sure that the first option is a URL we can crawl
  url = URI(ARGV[0])
rescue
  puts <<-INFO
Usage:
  cloud_crawler test <url>

Synopsis:
  Crawls a site starting at the given URL and outputs the total number
  of unique pages on the site.
INFO
  exit(0)
end

CloudCrawler.crawl_now(url) 
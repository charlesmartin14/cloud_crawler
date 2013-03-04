require 'cloud_crawler'
require 'optparse'
require 'ostruct'

begin
  # make sure that the first option is a URL we can crawl
  root = URI(ARGV[0])
rescue
  puts <<-INFO
Usage:
  anemone serialize [options] <url>

Synopsis:
  Crawls a site starting at the given URL and saves the resulting
  PageStore object to a file using Marshal serialization.

Options:
  -o, --output filename      Filename to save PageStore to. Defaults to crawl.{Time.now}
INFO
  exit(0)
end



# parse command-line options
opts = OptionParser.new
opts.on('-o', '--output filename') {|o| options.output_file = o }
opts.parse!(ARGV)

CloudCrawler.crawl(root) do |crawler|
  crawler.after_crawl do |pages|
    open(options.output_file, 'w') {|f| Marshal.dump(pages, f)}
  end
end

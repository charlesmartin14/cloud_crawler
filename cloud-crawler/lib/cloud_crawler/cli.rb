module CloudCrawler
  module CLI
    COMMANDS = %w[count pagedepth serialize url-list]
    
    def self.run
      command = ARGV.shift
      
      if COMMANDS.include? command
        load "cloud_crawler/cli/#{command.tr('-', '_')}.rb"
      else
        puts <<-INFO
CloudCrawler is a web spider framework that can collect
useful information about pages it visits.

Usage:
  cloud_crawler <command> [arguments]

Commands:
  #{COMMANDS.join(', ')}
INFO
      end
    end
  end
end
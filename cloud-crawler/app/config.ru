require 'rubygems'
require 'bundler/setup'
#require 'qless'

require "#{File.dirname(__FILE__)}/app"

set :environment, :development #ENV['RACK_ENV'].to_sym
set :app_file,  'app.rb'
# disable :run
# set :protection, :except => :frame_options


log = File.new("logs/sinatra.log", "a")
STDOUT.reopen(log)
STDERR.reopen(log)

#Qless::Server.client = Qless::Client.new(:host => "localhost", :port => 6379)

#Rack::Builder.new do
 # use SomeMiddleware
 # map('/qless')          { run Qless::Server.new }
#end

run Sinatra::Application

#TODO  mount this directly...how to do this locally?
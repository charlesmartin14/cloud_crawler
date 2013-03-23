#!/usr/bin/env ruby
require 'rubygems'
require 'sinatra'
require 'redis'
require 'json'
require 'uri'
require 'htmlentities'

configure do
  REDIS = Redis.new
end


get '/hello' do
  REDIS['hello']='hi ya from redis'
  REDIS['hello']
end

get '/' do
  "Hello World"
end


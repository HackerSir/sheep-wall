#!/usr/bin/env ruby

$:.push File.expand_path "../lib", File.dirname(__FILE__)

require "rubygems"
require "bundler/setup"
Bundler.setup(:default)

require "eventmachine"
require "faye"
require "redis"
require "json"

def new_redis
  if ENV.key?('REDIS_HOST')
    redis = Redis.new host: ENV['REDIS_HOST'], port: ENV['REDIS_PORT']
  elsif ENV.key? 'REDIS_URL'
    redis = Redis.new url: ENV['REDIS_URL']
  else
    redis = Redis.new
  end
end

ws = Faye::RackAdapter.new mount: '/faye'
ws.add_websocket_extension(PermessageDeflate)

ws.on(:subscribe) do |client_id, channel|
  puts "[  SUBSCRIBE] #{client_id} -> #{channel}"
end

ws.on(:unsubscribe) do |client_id, channel|
  puts "[UNSUBSCRIBE] #{client_id} -> #{channel}"
end

ws.on(:disconnect) do |client_id|
  puts "[ DISCONNECT] #{client_id}"
end

def ws.log mesg
  puts mesg
end

Thread.new do
  EM.run
end

Thread.new do
  listener, fetcher = new_redis(), new_redis()
  listener.subscribe("new-sheep") do |ev|
    ev.message do |channel, mesg|
      ws.get_client.publish "/update", fetcher.hgetall(mesg).to_json
      p mesg
    end
  end
end

use Rack::Static, :urls => {"/" => 'index.html'}, :root => 'public'

run ws

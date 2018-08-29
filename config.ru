#!/usr/bin/env ruby

$:.push File.expand_path "../lib", File.dirname(__FILE__)

require "rubygems"
require "bundler/setup"
Bundler.setup(:default)

require "eventmachine"
require "faye"
require "permessage_deflate"
require "redis"
require "json"
require "pry"

class LimitPublish
  def incoming(mesg,cb)
    puts "\e[1;32m#{mesg.inspect}\e[m"
    puts "\e[1;33m#{cb[mesg].inspect}\e[m"
  end
end

def new_redis
  if ENV.key?('REDIS_HOST')
    redis = Redis.new host: ENV['REDIS_HOST'], port: ENV['REDIS_PORT']
  elsif ENV.key? 'REDIS_URL'
    redis = Redis.new url: ENV['REDIS_URL']
  else
    redis = Redis.new
  end
  redis
end

ws = Faye::RackAdapter.new mount: '/faye', ping: 5
ws.add_websocket_extension(PermessageDeflate)
ws.add_extension(LimitPublish.new)

ws.on(:subscribe) do |client_id, channel|
  puts "[  SUBSCRIBE] #{client_id[0,5]} -> #{channel}"
end

ws.on(:unsubscribe) do |client_id, channel|
  puts "[UNSUBSCRIBE] #{client_id[0,5]} -> #{channel}"
end

ws.on(:publish) do |client_id, channel, data|
  puts "[    PUBLISH] #{client_id[0,5]} -> #{channel}: #{data}"
end

ws.on(:disconnect) do |client_id|
  puts "[ DISCONNECT] #{client_id[0,5]}"
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
      p mesg
      ws.get_client.publish "/update", fetcher.hgetall(mesg).to_json
    end
  end
end

use Rack::Static, :urls => {"/" => 'index.html'}, :root => 'public'

run ws

# encoding: utf-8

require 'bundler/setup'
Bundler.require
require 'uri'
require 'active_support/cache'

set :erubis, :escape_html => true

INSTAPAPER = Instapi.new(ENV['INSTAPAPER_USERNAME'], ENV['INSTAPAPER_PASSWORD'])
CACHE = ActiveSupport::Cache.lookup_store(:dalli_store)
CACHE_EXPIRES_IN = ENV['CACHE_EXPIRES_IN'].to_i rescue 10

def text(url)
  if result = CACHE.read(url)
    puts "read cache for: #{url}"
    result
  else
    puts "write cache for: #{url}"
    result = Instapi.text(URI.encode(url))
    CACHE.write(url, result, :expires_in => CACHE_EXPIRES_IN)
    result
  end
end

error do
  "System Error :("
end

get '/' do
  erubis :index
end

get '/t' do
  @url = params[:url]
  @text = text(@url)
  erubis :text
end

get '/u' do
  @bookmarks = INSTAPAPER.unread
  erubis :bookmarks
end
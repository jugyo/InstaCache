# encoding: utf-8

require 'bundler/setup'
Bundler.require
require 'uri'
require 'active_support/cache'

use Rack::Session::EncryptedCookie, :secret => "\x84rN\x95b\x13\x85\x9D\x02r\xCF9F\x93$\x16"
set :erubis, :escape_html => true
set :show_exceptions, false

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

helpers do
  def instapaper
    if session.key?(:username) && session.key?(:password)
      Instapi.new(session[:username], session[:password])
    end
  end

  def logged_in?
    !!instapaper
  end
end

error Instapi::LoginError do
  session.clear
  flash[:notice] = "Invalid username or password :("
  redirect '/login'
end

get '/' do
  if logged_in?
    erubis :index
  else
    redirect '/login'
  end
end

get '/login' do
  erubis :login
end

post '/login' do
  session[:username] = params[:username]
  session[:password] = params[:password]
  instapaper.login! # to verify user
  redirect '/'
end

get '/logout' do
  session.clear
  redirect '/login'
end

get '/t' do
  @id = params[:id]
  @url = params[:url]
  @text = text(@url)
  erubis :text
end

get '/u' do
  @bookmarks = instapaper.login!.unread
  erubis :bookmarks
end

post '/archive' do
  instapaper.login!.archive(params[:id])
end

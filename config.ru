require 'rubygems'
require 'sinatra'
require 'json'

set :environment, ENV['RACK_ENV'].to_sym
Tilt.register Tilt::ERBTemplate, 'html.erb'

disable :static, :run

get '/repo/:user/:repo' do |user, repo|
  json = File.read("public/data/#{user}_#{repo}.json") rescue (return 404)
  data = JSON.parse(json) rescue (return 500)
  erb :info, locals: {data: data}
end

get '/repo' do
  [301, {'Location' => '/ghdata'}, []]
end

get '/' do
  erb :index
end

get '/ghdata/*' do |filename|
    send_file "public/#{filename}"
end

run Sinatra::Application

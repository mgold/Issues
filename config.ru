require 'rubygems'
require 'sinatra'
require 'json'

set :environment, ENV['RACK_ENV'].to_sym
Tilt.register Tilt::ERBTemplate, 'html.erb'

disable :static, :run

get '/repo/:user/:repo' do |user, repo|
  json = File.read("data/srv/#{user}_#{repo}.json") rescue (return 404)
  data = JSON.parse(json) rescue (return 500)
  erb :info, locals: {data: data}
end

run Sinatra::Application

require 'rubygems'
require 'sinatra'
require 'json'

set :environment, ENV['RACK_ENV'].to_sym if ENV['RACK_ENV']
Tilt.register Tilt::ERBTemplate, 'html.erb'

#Remove this line to use Sintra for everything; keep it to use Nginx+Passenger
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

post '/' do
    return 500 unless params["userrepo"]
    return [400, {}, ["Input must include exactly one / character"]] unless params["userrepo"].count('/') == 1
    user, repo = params["userrepo"].split("/")
    if File.file?("public/data/#{user}_#{repo}.json")
        return [301, {'Location' => "/ghdata/repo/#{user}/#{repo}"}, []]
    end
    system "ruby download.rb #{user}/#{repo} && ruby analyze.rb #{user}/#{repo} &"
    erb :wait, locals: {userrepo: "#{user}/#{repo}"}
end

get '/ghdata/*' do |filename|
    send_file "public/#{filename}"
end

run Sinatra::Application if respond_to? :run

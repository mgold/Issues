require 'sinatra'
require 'json'

get '/:user/:repo' do |user, repo|
  json = File.read("data/srv/#{user}_#{repo}.json") rescue (return 404)
  data = JSON.parse(json) rescue (return 500)
  erb :info, locals: {data: data}
end

require 'sinatra'
require 'json'

Tilt.register Tilt::ERBTemplate, 'html.erb'

disable :static

get "/public/:asset" do |asset|
  send_file File.join(settings.public_folder, asset)
end

get '/:user/:repo' do |user, repo|
  json = File.read("data/srv/#{user}_#{repo}.json") rescue (return 404)
  data = JSON.parse(json) rescue (return 500)
  erb :info, locals: {data: data}
end

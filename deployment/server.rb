require 'sinatra'
require "socket"

set :bind, '0.0.0.0'

get '/' do
  "Hello world!"
end

get '/user/:name' do
  "Hello #{params['name']} from #{Socket.gethostname}"
end

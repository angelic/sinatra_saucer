require 'rubygems'
require 'sinatra'
require 'sinatra_saucer'

set :run, false
set :environment, ENV['RACK_ENV'] || :development
run Sinatra::Application

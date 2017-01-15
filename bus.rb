require 'sinatra'
require 'net/http'
require 'json'
require 'erb'
require 'cgi'

require 'net/http'
require 'uri'
require './lib/lookup'

set :views,      File.dirname(__FILE__) + '/views'
set :public_dir, File.dirname(__FILE__) + '/static'

get '/' do
  if params[:search] && params[:search] != ""
    if id = Lookup.id_from_sms_code(params[:search])
      redirect to("/stop/#{id}")
    else
      @flash = "Bus stop not found"
    end
  elsif params[:lat] && params[:lon] && params[:lat] != "" && params[:lon] != ""
    # @search_results = STOPS.select { |x| approximate_distance_between(x, params) < 0.005 }
    # @search_results.sort!{ |a, b| approximate_distance_between(a, params) <=> approximate_distance_between(b, params) }
  end
  erb :index
end

get '/stop/:stop_id' do |stop_id|
  @arrivals = Lookup.get_arrivals(stop_id)
  if @arrivals.any?
    arr = @arrivals.first
    @stop_name = "#{arr["stationName"]} (#{arr["platformName"]})"
  end
  erb :stop
end

get '/stop/:stop_id/partial' do |stop_id|
  @arrivals = Lookup.get_arrivals(stop_id)
  erb :indicator_table, layout: false
end

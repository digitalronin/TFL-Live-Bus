require 'sinatra'
require 'net/http'
require 'json'
require 'erb'
require 'cgi'

require 'net/http'
require 'uri'
require './lib/tfl_api'

set :views,      File.dirname(__FILE__) + '/views'
set :public_dir, File.dirname(__FILE__) + '/static'

get '/' do
  if params[:search] && params[:search] != ""
    if id = TflApi.id_from_sms_code(params[:search])
      redirect to("/stop/#{id}")
    else
      @flash = "Bus stop not found"
    end
  elsif params[:lat] && params[:lon] && params[:lat] != "" && params[:lon] != ""
    @bus_stops = TflApi.bus_stops_near_point(longitude: params[:lon], latitude: params[:lat])
  end
  erb :index
end

get '/nearby' do
  erb :nearby
end

get '/stop/:stop_id' do |stop_id|
  @arrivals = TflApi.get_arrivals(stop_id)
  if @arrivals.any?
    arr = @arrivals.first
    @stop_name = "#{arr["stationName"]} (#{arr["platformName"]})"
  end
  erb :stop
end

get '/stop/:stop_id/partial' do |stop_id|
  @arrivals = TflApi.get_arrivals(stop_id)
  erb :indicator_table, layout: false
end

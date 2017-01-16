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
  search = params[:search].to_s.strip

  if search && search != ""
    case search
    when /\A\d+\z/   # Search for a bus stop by its numeric SMS code
      if id = TflApi.id_from_sms_code(search)
        redirect to("/stop/#{id}")
      else
        @flash = "Bus stop not found"
      end
    else  # Search for a bus stop by name
      @stop_points = TflApi.search_stop_points_by_name(search)
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
    @title = @stop_name
  end
  erb :stop
end

get '/stop/:stop_id/partial' do |stop_id|
  @arrivals = TflApi.get_arrivals(stop_id)
  erb :indicator_table, layout: false
end

get '/stop_point/:id' do |id|
  @bus_stops = TflApi.bus_stops_by_stop_point_id(id)
  erb :index
end


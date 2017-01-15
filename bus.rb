require 'sinatra'
require 'net/http'
require 'json'
require 'erb'
require 'cgi'
require 'awesome_print'

require 'net/http'
require 'uri'
require './lib/lookup'

set :views,      File.dirname(__FILE__) + '/views'
set :public_dir, File.dirname(__FILE__) + '/static'

STOPS = JSON.parse(File.read("./bus_stops.json"))["markers"]

# The part before the docpath is in upper case because
# that results in a smaller (i.e. fewer pixels) QR code
# which is easier to scan
STOP_URL = 'HTTP://BUS.ABSCOND.ORG/stop'

get '/' do
  if params[:search] && params[:search] != ""
    if id = Lookup.id_from_sms_code(params[:search])
      redirect to("/stop/#{id}")
    else
      @flash = "Bus stop not found"
    end
  elsif params[:lat] && params[:lon] && params[:lat] != "" && params[:lon] != ""
    @search_results = STOPS.select { |x| approximate_distance_between(x, params) < 0.005 }
    @search_results.sort!{ |a, b| approximate_distance_between(a, params) <=> approximate_distance_between(b, params) }
  end
  erb :index
end

get '/nearby' do
  erb :nearby
end

get '/stop/:stop_id' do |stop_id|
  # TODO: @stop = STOPS.select {|x| x["id"] =~ /#{stop_id}/i}.first
  @arrivals = get_arrivals(stop_id)
  if @arrivals.any?
    arr = @arrivals.first
    @stop_name = "#{arr["stationName"]} (#{arr["platformName"]})"
  end
  erb :stop
end

get '/qr' do
  if params[:search] && params[:search] != ""
    @stop = STOPS.select {|x| x["id"] =~ /#{params[:search]}/i}.first
  end
  erb :qr
end

get '/qr/:stop_id' do |stop_id|
  @stop = STOPS.select {|x| x["id"] =~ /#{stop_id}/i}.first
  url  = [STOP_URL, stop_id].join('/')
  @qr_img_url = "https://chart.googleapis.com/chart?chs=300x300&cht=qr&chl=#{CGI.escape url}"

  erb :qr
end

get '/stop/:stop_id/partial' do |stop_id|
  @arrivals = get_arrivals(stop_id)
  erb :indicator_table
end

get '/stop/:stop_id/curl' do |stop_id|
  get_stop_json(stop_id)
  @json["arrivals"].collect{|x| "#{x["routeId"]} | #{x["estimatedWait"]}\n"}
end

get '/stop/:stop_id/jsonp' do |stop_id|
  headers 'Content-Type' => "text/javascript"
  "bus_json(#{make_request(stop_id)})"
end

def get_arrivals(stop_id)
  response = make_request(stop_id)
  JSON.parse(response).sort {|a,b| a["timeToStation"] <=> b["timeToStation"]}
end

def get_stop_json(stop_id)
  response = make_request(stop_id)
  @json = JSON.parse(response)
end

def make_request(stop_id)
  Net::HTTP.get(URI.parse("https://api.tfl.gov.uk/StopPoint/#{stop_id}/arrivals"))
end

def approximate_distance_between(stop, coords)
  lat_diff = (stop["lat"].to_f - coords[:lat].to_f).abs
  lon_diff = (stop["lng"].to_f - coords[:lon].to_f).abs
  diff = Math.sqrt(lat_diff**2 + lon_diff**2)
end

class TflApi
  STOP_POINT_URL = 'https://api.tfl.gov.uk/StopPoint'

  BUS_STOP_TYPE = 'NaptanPublicBusCoachTram'

  class BusStop
    attr_reader :id, :commonName, :indicator, :lat, :lon

    def initialize(params)
      @id         = params.fetch('id')
      @commonName = params.fetch('commonName')
      @indicator  = params['indicator']
      @lat        = params.fetch('lat')
      @lon        = params.fetch('lon')
    end
  end

  class StopPoint
    attr_reader :id, :name, :lat, :lon

    def initialize(params)
      @id   = params.fetch('id')
      @name = params.fetch('name')
      @lat  = params.fetch('lat')
      @lon  = params.fetch('lon')
    end
  end

  # Take a 5-digit bus stop SMS code (e.g. '72269') and return the corresponding Naptan ID (490008041N)
  def self.id_from_sms_code(value)
    response = self.get("#{STOP_POINT_URL}/Sms/#{value}")
    # Although the API docs say we should get JSON back, and that's what happens on the TFL API explorer,
    # https://api.tfl.gov.uk/swagger/ui/index.html?url=/swagger/docs/v1#!/StopPoint/StopPoint_GetBySms
    # in practice, I only ever got redirected to /StopPoint/[naptan ID]
    (response['location']) ? response['location'].sub(/.*\//, '') : nil
  end

  def self.get_arrivals(stop_id)
    response = self.get("#{STOP_POINT_URL}/#{stop_id}/arrivals")
    JSON.parse(response.body).sort {|a,b| a["timeToStation"] <=> b["timeToStation"]}
  end

  def self.search_stop_points_by_name(string)
    url = STOP_POINT_URL + "/Search?query=" + URI.encode(string)
    response = self.get(url)
    JSON.parse(response.body)['matches'].map {|i| StopPoint.new(i)}
  end

  def self.bus_stops_by_stop_point_id(id)
    url = STOP_POINT_URL + '/' + id
    response = self.get(url)
    JSON.parse(response.body)['children']
      .find_all {|i| i['stopType'] == BUS_STOP_TYPE}
      .map {|i| BusStop.new(i)}
  end

  # The point + radius form of the TFL API doesn't seem to work
  # https://api.tfl.gov.uk/swagger/ui/index.html?url=/swagger/docs/v1#!/StopPoint/StopPoint_GetByGeoPoint
  # But, the version below, based on a bounding box, works fine
  def self.bus_stops_near_point(longitude:, latitude:)
    # 0.001 of long/lat is ~69 metres
    distance = 0.005

    long = longitude.to_f
    lat  = latitude.to_f

    swLon = (long - distance).round(5)
    swLat = (lat  - distance).round(5)
    neLon = (long + distance).round(5)
    neLat = (lat  + distance).round(5)

    coords = "swLat=#{swLat}&neLat=#{neLat}&swLon=#{swLon}&neLon=#{neLon}"
    url = STOP_POINT_URL + "?#{coords}&stopTypes=#{BUS_STOP_TYPE}&modes=bus"

    response = self.get(url)
    JSON.parse(response.body)
      .map {|i| BusStop.new(i)}
      .sort {|a,b|
        self.approx_distance(a, long, lat) <=> approx_distance(b, long, lat)
      }
  end

  # private

  def self.get(url)
    uri = URI(url)
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri)
    https.request(request)
  end

  def self.approx_distance(bus_stop, longitude, latitude)
    lat_diff = (bus_stop.lat.to_f - latitude).abs
    lon_diff = (bus_stop.lon.to_f - longitude).abs
    Math.sqrt(lat_diff**2 + lon_diff**2)
  end
end

class Lookup

  def self.id_from_sms_code(value)
    new.id_from_sms_code value
  end

  # Take a 5-digit bus stop SMS code (e.g. '72269') and return the corresponding Naptan ID (490008041N)
  def id_from_sms_code(value)
    puts "Lookup#find(#{value}) ..............................."
    response = get("https://api.tfl.gov.uk/StopPoint/Sms/#{value}")
    # Although the API docs say we should get JSON back, and that's what happens on the TFL API explorer,
    # https://api.tfl.gov.uk/swagger/ui/index.html?url=/swagger/docs/v1#!/StopPoint/StopPoint_GetBySms
    # in practice, I only ever got redirected to /StopPoint/[naptan ID]
    (response['location']) ? response['location'].sub(/.*\//, '') : nil
  end

  private

  def get(url)
    uri = URI(url)
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri)
    https.request(request)
  end
end

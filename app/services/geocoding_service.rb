# frozen_string_literal: true

class GeocodingService
  # Returns a hash: { lat:, lon:, location_name: } or nil if not found
  def self.lookup(query)
    geo_results = Geocoder.search(query)
    geo_result = geo_results.find { |r| r.country_code&.upcase == "US" } || geo_results.first
    return nil unless geo_result&.coordinates
    lat, lon = geo_result.coordinates
    location_name = [
      geo_result.city || geo_result.data["city"] || geo_result.data["town"] || geo_result.data["village"],
      geo_result.state || geo_result.data["state"],
      geo_result.country || geo_result.data["country"]
    ].compact.join(", ")
    { lat: lat, lon: lon, location_name: location_name }
  end
end

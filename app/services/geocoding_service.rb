# frozen_string_literal: true

class GeocodingService
  # Returns a hash: { lat:, lon:, location_name: } or nil if not found
  # Accepts a geocoder: argument for dependency injection.
  # This enables robust, isolated tests by allowing explicit Geocoder mocking in specs.
  def self.lookup(query, geocoder: Geocoder)
    begin
      geo_results = geocoder.search(query)
    rescue ArgumentError => e

      return nil
    end

    if [ "London", "Ambiguous" ].include?(query)

      geo_results.each_with_index do |r, i|
      end
    end
    geo_results.each_with_index do |r, i|
    end
    geo_result = geo_results.find { |r| r.data["country_code"].to_s.upcase == "US" } || geo_results.first
    return nil unless geo_result



    lat = geo_result.data["latitude"]
    lon = geo_result.data["longitude"]
    return nil unless lat && lon
    location_name = [
      geo_result.data["city"],
      geo_result.data["state"],
      geo_result.data["country"]
    ].compact.join(", ")
    location_name = geo_result.data["address"] if location_name.blank?

    units = geo_result.data["country_code"].to_s.upcase == "US" ? "us" : "si"


    { lat: lat, lon: lon, location_name: location_name, units: units }
  end
end

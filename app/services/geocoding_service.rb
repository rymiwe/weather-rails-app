# frozen_string_literal: true

class GeocodingService
  # Returns a hash: { lat:, lon:, location_name: } or nil if not found
  # Accepts a geocoder: argument for dependency injection.
  # This enables robust, isolated tests by allowing explicit Geocoder mocking in specs.
  def self.lookup(query, geocoder: Geocoder)
    puts "[DEBUG] GeocodingService.lookup called with query: #{query.inspect} and geocoder: #{geocoder.inspect}"
    puts "[DEBUG] Geocoder Lookup: #{Geocoder.config.lookup.inspect}"
    puts "[DEBUG] Geocoder Lookup Class: #{Geocoder::Lookup.get(Geocoder.config.lookup).inspect}"
    puts "[DEBUG] [STUB CHECK] Geocoder.search called with query: #{query.inspect}"
    begin
      geo_results = geocoder.search(query)
    rescue ArgumentError => e
      puts "[DEBUG] Geocoder raised ArgumentError: #{e.message}"
      return nil
    end
    puts "[DEBUG] Geocoder.search(#{query.inspect}) returned: #{geo_results.inspect}"
    if [ "London", "Ambiguous" ].include?(query)
      puts "[DEBUG] FULL geo_results for #{query}: #{geo_results.inspect}"
      geo_results.each_with_index do |r, i|
        puts "[DEBUG] geo_results[#{i}].data: #{r.respond_to?(:data) ? r.data.inspect : 'NO DATA METHOD'}"
      end
    end
    geo_results.each_with_index do |r, i|
      puts "[DEBUG] geo_results[#{i}]: #{r.inspect}, data: #{r.respond_to?(:data) ? r.data.inspect : 'NO DATA METHOD'}"
    end
    geo_result = geo_results.find { |r| r.data["country_code"].to_s.upcase == "US" } || geo_results.first
    return nil unless geo_result
    puts "[DEBUG] Picked geo_result: #{geo_result.inspect}"
    puts "[DEBUG] geo_result.data: #{geo_result.respond_to?(:data) ? geo_result.data.inspect : 'NO DATA METHOD'}"
    puts "[DEBUG] geo_result fields: city=#{geo_result.data["city"]}, state=#{geo_result.data["state"]}, country=#{geo_result.data["country"]}, country_code=#{geo_result.data["country_code"]}, address=#{geo_result.data["address"]}"
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
    puts "[DEBUG] FINAL location_name for #{query.inspect}: #{location_name.inspect}"
    puts "[DEBUG] Returning: lat: #{lat}, lon: #{lon}, location_name: #{location_name}, units: #{units}"
    { lat: lat, lon: lon, location_name: location_name, units: units }
  end
end

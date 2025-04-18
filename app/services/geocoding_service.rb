# frozen_string_literal: true

class GeocodingService
  # Returns a hash: { lat:, lon:, location_name: } or nil if not found
  # Accepts a geocoder: argument for dependency injection.
  # This enables robust, isolated tests by allowing explicit Geocoder mocking in specs.
  def self.lookup(query, geocoder: Geocoder)
    # If the query looks like a US ZIP code, bias the result using Geocoder's params option
    geocode_options = {}
    if query.to_s.match?(/^\d{5}$/)
      geocode_options[:params] = { countrycodes: "us" }
    end

    begin
      geo_results = geocoder.search(query, geocode_options)
    rescue ArgumentError => e

      return nil
    end


    geo_result = geo_results.find { |r| r.data["country_code"].to_s.upcase == "US" } || geo_results.first
    unless geo_result

      return nil
    end

    lat = geo_result.data["latitude"] || geo_result.data["lat"]
    lon = geo_result.data["longitude"] || geo_result.data["lon"]
    unless lat && lon

      return nil
    end
    # Prefer extracting from address hash if present
    address = geo_result.data["address"] || {}
    locality = address["city"] || address["town"] || address["village"] || address["suburb"] || address["neighbourhood"]
    state = address["state"]
    country = address["country"]
    location_name = [ locality, state, country ].compact.join(", ")
    units = geo_result.data["country_code"].to_s.upcase == "US" ? "us" : "si"

    { lat: lat, lon: lon, location_name: location_name, units: units }
  end
end

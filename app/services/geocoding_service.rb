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

  # FORCE 'us' units for any location in the US
  # Note: We check the query itself as well as the result in case the API doesn't return correct country codes
  us_query = query.to_s.match?(/\b(US|USA|Oregon|Washington|California|New York|Texas)\b/i)
  us_result = (country_code = geo_result.data["country_code"].to_s.upcase) == "US" || country.to_s.include?("United States")

  # Simple rule: If it's a US location or query, use US units (Fahrenheit)
  units = (us_query || us_result) ? "us" : "si"

  # DEBUGGING: Check what's happening with units detection
  Rails.logger.info "*** UNITS DETECTION ***"
  Rails.logger.info "Query: #{query}"
  Rails.logger.info "Location: #{location_name}"
  Rails.logger.info "Country code: #{geo_result.data['country_code']}"
  Rails.logger.info "Country: #{country}"
  Rails.logger.info "State: #{state}"
  Rails.logger.info "Is US query? #{us_query}"
  Rails.logger.info "Is US result? #{us_result}"
  Rails.logger.info "Using units: #{units}"

  # Always log API calls in development for debugging
  if Rails.env.development?
    puts "\n*** GEOCODING RESULT ***"
    puts "Query: #{query}"
    puts "Location: #{location_name}"
    puts "Units: #{units} (#{units == 'us' ? 'Fahrenheit' : 'Celsius'})"
    puts "Lat/Lon: #{lat}, #{lon}"
  end

  { lat: lat, lon: lon, location_name: location_name, units: units }
  end
end

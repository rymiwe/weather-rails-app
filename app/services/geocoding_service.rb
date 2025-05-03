# frozen_string_literal: true

class GeocodingService
  class << self
    # Use Rails' built-in delegation instead of manually defining the class method
    def lookup(query, geocoder: Geocoder)
      new(geocoder).lookup(query)
    end
  end

  attr_reader :geocoder

  def initialize(geocoder = Geocoder)
    @geocoder = geocoder
  end

  # Returns a hash: { lat:, lon:, location_name:, units: } or nil if not found
  def lookup(query)
    geo_result = find_geo_result(query)
    return nil unless geo_result

    coordinates = extract_coordinates(geo_result)
    return nil unless coordinates[:lat] && coordinates[:lon]

    location_name = extract_location_name(geo_result)
    units = determine_units(query, geo_result)

    log_result(query, location_name, units, coordinates) if Rails.env.development?

    {
      lat: coordinates[:lat],
      lon: coordinates[:lon],
      location_name: location_name,
      units: units
    }
  end

  private

  def find_geo_result(query)
    geocode_options = build_geocode_options(query)

    begin
      geo_results = geocoder.search(query, geocode_options)
      geo_results.find { |r| r.data["country_code"].to_s.upcase == "US" } || geo_results.first
    rescue ArgumentError => e
      Rails.logger.error("Geocoding error: #{e.message} for query: #{query}")
      nil
    end
  end

  def build_geocode_options(query)
    # If the query looks like a US ZIP code, bias the result using Geocoder's params option
    return {} unless query.to_s.match?(/^\d{5}$/)

    { params: { countrycodes: "us" } }
  end

  def extract_coordinates(geo_result)
    {
      lat: geo_result.data["latitude"] || geo_result.data["lat"],
      lon: geo_result.data["longitude"] || geo_result.data["lon"]
    }
  end

  def extract_location_name(geo_result)
    # Prefer extracting from address hash if present
    address = geo_result.data["address"] || {}
    locality = address["city"] || address["town"] || address["village"] || address["suburb"] || address["neighbourhood"]
    state = address["state"]
    country = address["country"]

    [ locality, state, country ].compact.join(", ")
  end

  def determine_units(query, geo_result)
    # FORCE 'us' units for any location in the US
    address = geo_result.data["address"] || {}
    country = address["country"]

    us_query = query.to_s.match?(/\b(US|USA|Oregon|Washington|California|New York|Texas)\b/i)
    us_result = geo_result.data["country_code"].to_s.upcase == "US" || country.to_s.include?("United States")

    # Simple rule: If it's a US location or query, use US units (Fahrenheit)
    (us_query || us_result) ? "us" : "si"
  end

  def log_result(query, location_name, units, coordinates)
    Rails.logger.debug do
      [
        "*** GEOCODING RESULT ***",
        "Query: #{query}",
        "Location: #{location_name}",
        "Units: #{units} (#{units == 'us' ? 'Fahrenheit' : 'Celsius'})",
        "Lat/Lon: #{coordinates[:lat]}, #{coordinates[:lon]}"
      ].join("\n")
    end
  end
end

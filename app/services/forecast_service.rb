# frozen_string_literal: true

class ForecastService
  # Returns [forecast, from_cache, error_message, location_name, units]
  # Accepts a geocoder: argument for dependency injection.
  # Accepts a weather_client: argument for testability.
  # This enables robust, isolated tests by allowing explicit Geocoder and weather client mocking in specs.
  def self.fetch(query, refresh: false, geocoder: Geocoder, weather_client: PirateWeatherClient)
    return [ nil, false, "Please enter an query.", nil, nil ] if query.blank?

    geo_data = GeocodingService.lookup(query, geocoder: geocoder)
    unless geo_data
      return [ nil, false, "Could not geocode query.", nil, nil ]
    end
    lat = geo_data[:lat]
    lon = geo_data[:lon]
    location_name = geo_data[:location_name]
    units = geo_data[:units] || "us"

    cached = ForecastCacheService.read(lat, lon)
    if cached.is_a?(Forecast)
      return [ cached, true, nil, location_name, units ] unless refresh
    end

    begin
      client = weather_client.is_a?(Class) ? weather_client.new : weather_client
      raw = client.fetch_forecast(lat, lon, units: units)
      if raw.nil?
        return [ nil, false, "Could not retrieve forecast data.", location_name, units ]
      end
      forecast = Forecast.new(
        temperature: raw.dig("currently", "temperature"),
        summary: raw.dig("currently", "summary"),
        icon: raw.dig("currently", "icon"),
        units: units,
        location: location_name,
        raw_data: raw
      )
      ForecastCacheService.write(lat, lon, forecast)
      [ forecast, false, nil, location_name, units ]
    rescue => e
      [ nil, false, "Error fetching weather data.", location_name, units ]
    end
  end
end
